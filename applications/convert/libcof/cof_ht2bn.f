      SUBROUTINE COF_HT2BN( TYPE, SIZE, BNTYPE, STATUS )
*+
*  Name:
*     COF_HT2BN

*  Purpose:
*     Converts an HDS type into the form (type) for a FITS binary table.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL COF_HT2BN( TYPE, SIZE, BNTYPE, STATUS )

*  Description:
*     This routine converts an HDS data type into the value that is
*     assigned to the TFORMn keyword in the FITS binary-table header.
*     Most types have a one-to-one mapping.  However, there are no
*     equivalents _BYTE and _UWORD, and the next integer type is used,
*     for example _BYTE maps to rW.  The non-standard rAw is used
*     for character arrays.

*  Arguments:
*     TYPE = CHARACTER * ( * ) (Given)
*        The HDS data type.
*     SIZE = INTEGER (Given)
*        The number of elements in the array.
*     BNTYPE = CHARACTER * ( * ) (Returned)
*        The FITS binary table form for the given size and HDS data
*        type.  It is one of the following: rL, rB, rI, rJ, rA, rAw, rE,
*        rD; where r is the repeat count for an array.  Note that the
*        supplied length must be adequate to hold large repeat counts.
*        Nine chacters should suffice.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1994 June 21 (MJC):
*        Original version.
*     1996 July 23 ({author_identifier}):
*        Fixed bug arising out of HEASARC rAw extension, because r is
*        not the repeat count but the total width.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) TYPE
      INTEGER SIZE

*  Arguments Returned:
      CHARACTER * ( * ) BNTYPE

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Effective length of a string

*  Local Variables:
      INTEGER ASKCOL             ! Column location of asterisk in type
      INTEGER NC                 ! Number of characters in size
      CHARACTER * ( 10 ) CLEN    ! Length of a chaaracter element in
                                 ! bytes
      CHARACTER * ( 12 ) CSIZE   ! String form of the array size and
                                 ! work value
      INTEGER WIDTH              ! Width of a character value
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Convert the repeat count into a string.
      CALL CHR_ITOC( SIZE, CSIZE, NC )

*  Assign the appropriate FITS TFORM string's value for each data type.
      IF ( TYPE .EQ. '_UBYTE' ) THEN
         CALL CHR_APPND( 'B', CSIZE, NC )

      ELSE IF ( TYPE .EQ. '_BYTE' .OR. TYPE .EQ. '_WORD' ) THEN
         CALL CHR_APPND( 'I', CSIZE, NC )

      ELSE IF ( TYPE .EQ. '_UWORD' .OR. TYPE .EQ. '_INTEGER' ) THEN
         CALL CHR_APPND( 'J', CSIZE, NC )

      ELSE IF ( TYPE .EQ. '_REAL' ) THEN
         CALL CHR_APPND( 'E', CSIZE, NC )

      ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
         CALL CHR_APPND( 'D', CSIZE, NC )

      ELSE IF ( TYPE .EQ. '_LOGICAL' ) THEN
         CALL CHR_APPND( 'L', CSIZE, NC )

      ELSE IF ( INDEX( TYPE, '_CHAR' ) .NE. 0 ) THEN

*  Extract the length of a character string by looking for the asterisk.
*  No asterisk means _CHAR*1.
         ASKCOL = INDEX( TYPE, '*' )
         IF ( ASKCOL .EQ. 0 ) THEN
            CLEN = '1'
         ELSE
            CLEN = TYPE( ASKCOL + 1: )
         END IF

*  Create the TFORM value.  This is the standard rA, where r is the
*  number of characters.
         IF ( SIZE .EQ. 1 ) THEN
            NC = CHR_LEN( CLEN )
            CALL CHR_APPND( 'A', CLEN, NC )
            CSIZE = CLEN

*  This is not.  It uses the HEASARC rAw form.  Note that r is *not* the
*  repeat count, but is the total width.  So have to redefine the start
*  of the string.
         ELSE
            CALL CHR_CTOI( CLEN, WIDTH, STATUS )
            CALL CHR_ITOC( WIDTH * SIZE, CSIZE, NC )
            CALL CHR_APPND( 'A', CSIZE, NC )
            CALL CHR_APPND( CLEN, CSIZE, NC )
         END IF
      END IF

*  Copy the work value to the returned argument.
      BNTYPE = CSIZE

      END
