      SUBROUTINE IMG1_WREX<T>( SLOT, ESLOT, ITEM, VALUE, STATUS )
*+
* Name:
*    IMG1_WREXx

*  Purpose:
*     Writes a "normal" extension item.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IMG1_WREXx( SLOT, ESLOT, ITEM, VALUE, STATUS )

*  Description:
*     This routine creates or overwrites an object in an extension of
*     an NDF (this is the non-FITS case). If the object which is being
*     written exists then it is erased and re-created with the correct
*     type. The "name" of the extension object is ITEM; this may be
*     hierachical and refers to an object relative to the extension
*     locator. The HDS type of any structures which are created is set
*     to "IMG_EXTENSION".

*  Arguments:
*     SLOT = INTEGER (Given)
*        The NDF slot number.
*     ESLOT = INTEGER (Given)
*        The extension slot number.
*     ITEM = CHARACTER * ( * ) (Given)
*        The name of the extension item which will be written to. Note
*        this is relative to the locator defined by ESLOT and may be
*        hierarchical (e.g. BOUNDS.MAXX).
*     VALUE = <COMM> (Given)
*        The value of the extension item.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - There is a version of this routine for writing header items
*     of various types. Replace the "x" in the routine name by C, L, D,
*     R, or I as appropriate.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     26-JUL-1994 (PDRAPER):
*        Original version.
*     9-SEP-1994 (PDRAPER):
*        Now always uses "IMG_EXTENSION" as the type for structures and
*        erases/re-creates objects which exist (provided that this is
*        possible).
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IMG_CONST'        ! IMG_ constants
      INCLUDE 'IMG_ERR'          ! IMG_ error codes
      INCLUDE 'NDF_PAR'          ! NDF_ constants
      INCLUDE 'DAT_PAR'          ! HDS/DAT parameters

*  Global Variables:
      INCLUDE 'IMG_ECB'          ! IMG Extension Control Block
*        ECB_XNAME( IMG__MXPAR, IMG__MXEXT ) =
*           CHARACTER * ( NDF__SZXNM ) (Read)
*        The name of the extension
*
*        ECB_XLOC( IMG__MXPAR, IMG__MXEXT ) =
*           CHARACTER ( DAT__SZLOC ) (Read)
*        The locator to the extension.
*
*        ECB_XPSTK( IMG__MXPAR, IMG__MXEXT ) = INTEGER (Read)
*        Pointers to the stack of extension locators.
*
*        ECB_XNSTK( IMG__MXPAR, IMG__MXEXT ) = INTEGER (Read)
*        The number of locators in an extension stack.

      INCLUDE 'IMG_PCB'          ! IMG Parameter Control Block
*        PCB_INDF( IMG__MXPAR ) = INTEGER (Read)
*        NDF identifiers

*  Arguments Given:
      INTEGER SLOT
      INTEGER ESLOT
      CHARACTER * ( * ) ITEM
      <TYPE> VALUE

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL IMG1_INIT         ! Initialise common blocks
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Used length of string
      EXTERNAL CHR_SIMLR
      LOGICAL CHR_SIMLR          ! Character strings are equal apart
                                 ! from case

*  Local Constants:
      CHARACTER * ( DAT__SZTYP ) STYPE ! Type of any created structures
      PARAMETER ( STYPE = 'IMG_EXTENSION' )


*  Local Variables:
      CHARACTER * ( 2 * DAT__SZNAM ) OBJECT ! Name of "current" object
      CHARACTER * ( DAT__SZLOC ) LOC1 ! Primary locator
      CHARACTER * ( DAT__SZLOC ) LOC2 ! Secondary locator
      CHARACTER * ( DAT__SZLOC ) TMPLOC ! Temporary locator for eventual
                                        ! permanent storage
      CHARACTER * ( DAT__SZTYP ) TYPE ! Type of the object
      INTEGER IAT                ! Current start position in ITEM
      INTEGER INOW               ! New position of period
      INTEGER SIZE               ! Size of located object
      INTEGER STRLEN             ! Length of character primitive
      LOGICAL CREATE             ! Whether primitive needs creating
      LOGICAL MORE               ! ITEM string has more periods
      LOGICAL NEW                ! Whether the item is new or not
      LOGICAL YES                ! Object exists
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise MORE variable for first pass.
      MORE = .TRUE.

*  Current position in the ITEM string.
      IAT = 1

*  Clone the extension locator (so we can safely annul/re-use this
*  later).
      CALL DAT_CLONE( ECB_XLOC( SLOT, ESLOT ), LOC1, STATUS )

*  Item isn't new.
      NEW = .FALSE.

*  The basic idea is to loop locating each period in the item name until
*  no more are left. At each level getting a locator to the new object.
 1    CONTINUE                   ! Start of 'DO WHILE' loop
      IF ( STATUS .EQ. SAI__OK .AND. MORE ) THEN

*  Look for a period in the current string.
         INOW = INDEX( ITEM( IAT: ), '.' )
         IF ( INOW .EQ. 1 ) THEN

*  Have a leading '.' or '..' in name, just skip over this.
            IAT = IAT + 1
         ELSE IF ( INOW .NE. 0 ) THEN

*  Extract the name of the object to be accessed.
            INOW = IAT + INOW - 2
            OBJECT = ITEM( IAT: INOW )

*  Attempt to locate the object.
            CALL IMG1_FOBJ( LOC1, OBJECT, YES, LOC2, STATUS )
            IF ( .NOT. YES .AND. STATUS .EQ. SAI__OK ) THEN

*  The specified item doesn't exist, we may need to create it. The
*  intention is only to allow the creation of scalar objects
*  (non-scalars are fine it they exist already). DAT_NEW doesn't
*  return a bad status if an object name with trailing slice or cell
*  information is given, it just assumes that any string is a name, so
*  we need to check for the presence ourselves.
               IF ( INDEX( OBJECT, '(' ) .EQ. 0 .AND.
     :              INDEX( OBJECT, ')' ) .EQ. 0 ) THEN
                  CALL DAT_NEW( LOC1, OBJECT, STYPE, 0, 0, STATUS )
                  NEW = .TRUE.
                  CALL DAT_FIND( LOC1, OBJECT, LOC2, STATUS )
               ELSE

*  Must be a slice or subset specification. Issue an error.
                  STATUS = IMG__NOITM
                  CALL ERR_REP( 'IMG1_WREXX_NOSUB', 'The creation ' //
     :                 'of non-scalar components is not allowed.',
     :                 STATUS )
               END IF
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL MSG_SETC( 'OBJECT', OBJECT )
                  CALL MSG_SETC( 'ITEM', ITEM )
                  CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                  CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
                  CALL ERR_REP( 'IMG1_WREXX_NOCRE', 'Unable to ' //
     :                 'create the structure ^OBJECT, while writing ' //
     :                 'to the extension item ^ITEM, in the ' //
     :                 '^EXT extension of the NDF ^NDF.',
     :                 STATUS )
               END IF
            ELSE IF ( STATUS .NE. SAI__OK ) THEN

*  Probably an invalid name description, add to the error stack.
*  Problems with finding the object.
               CALL MSG_SETC( 'ITEM', ITEM )
               CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
               CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
               CALL ERR_REP( 'IMG1_RDEX<T>_NOITEM', 'The  ' //
     :              'item ^ITEM cannot be accessed (^EXT ' //
     :              'extension of the NDF ^NDF).', STATUS )
            END IF

*  Now release the locator to the previous object and make this the
*  current object.
            CALL DAT_ANNUL( LOC1, STATUS )
            LOC1 = LOC2
            IAT = INOW + 2
         ELSE

*  No period. Final object name (or first if not hierarchical) is
*  ITEM( IAT: )
            MORE = .FALSE.
            INOW = CHR_LEN( ITEM )
            OBJECT = ITEM( IAT: INOW )

*  Test for the existence of the object.
            CREATE = .TRUE.
            CALL IMG1_FOBJ( LOC1, OBJECT, YES, LOC2, STATUS )
            IF ( YES .AND. STATUS .EQ. SAI__OK ) THEN

*  Check that its type is correct and that it is a scalar primitive.
               CALL DAT_TYPE( LOC2, TYPE, STATUS )
               CALL DAT_PRIM( LOC2, YES, STATUS )
               CALL DAT_SIZE( LOC2, SIZE, STATUS )
               IF ( SIZE .NE. 1 .AND. STATUS .EQ. SAI__OK ) THEN

*  Target is non-scalar, this isn't allowed.
                  STATUS = IMG__NOITM
                  CALL MSG_SETC( 'ITEM', ITEM )
                  CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                  CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
                  CALL ERR_REP( 'IMG1_WREXX_NOCRE', 'Unable to ' //
     :                 'create the extension item ^ITEM, in the ' //
     :                 '^EXT extension of the NDF ^NDF. It is not ' //
     :                 'possible to write to non-scalar items.',
     :                 STATUS )
               ELSE IF ( .NOT. CHR_SIMLR( TYPE, '<HTYPE>' ) .OR.
     :                   .NOT. YES .AND. STATUS .EQ. SAI__OK )
     :         THEN

*  Erase the object. This will work only if the object isn't part of a
*  array (i.e. an element of an array, which should be indicated by ()
*  in the name). If it is part of an array then we must rely on a type
*  conversion or give up. We'll press on and hope the type conversion
*  works.
                  IF ( INDEX( '(', OBJECT ) .NE. 0 .OR.
     :                 INDEX( ')', OBJECT ) .NE. 0 ) THEN
                     CREATE = .FALSE.
                  ELSE

*  Must be ok to delete!
                     CALL DAT_ERASE( LOC1, OBJECT, STATUS )
                  END IF
               ELSE

*  Object exists is a scalar primitive and has the correct type. Need
*  to check the string length is large enough to receive the new value
*  if expecting to write a character string.
                  CREATE = .FALSE.
                  IF ( '<T>' .EQ. 'C' .AND. STATUS .EQ. SAI__OK ) THEN
                     CALL DAT_LEN( LOC2, STRLEN, STATUS )
                     IF ( STRLEN .LT. CHR_LEN( VALUE ) ) THEN

*  Rather than have a string truncation, remove the current object.
                        CALL DAT_ERASE( LOC1, OBJECT, STATUS )
                        CREATE = .TRUE.
                     END IF
                  END IF
               END IF
            ELSE

*  Object is definitely new, need to record this fact (so that extension
*  information about names etc. may be updated).
               NEW = .TRUE.
            END IF

*  Now check if the object needs to be created (didn't exist or has been
*  erased).
            IF ( CREATE .AND. STATUS .EQ. SAI__OK ) THEN

*  Make sure specification isn't for a slice or celll.
               IF ( INDEX( OBJECT, '(' ) .EQ. 0 .AND.
     :              INDEX( OBJECT, ')' ) .EQ. 0 ) THEN
                  IF ( '<T>' .EQ. 'C' ) THEN
                     CALL DAT_NEW0C( LOC1, OBJECT, CHR_LEN( VALUE ),
     :                    STATUS )
                  ELSE
                     CALL DAT_NEW0<T>( LOC1, OBJECT, STATUS )
                  END IF
                  CALL DAT_FIND( LOC1, OBJECT, LOC2, STATUS )
               ELSE

*  Cannot create cells or slices.
                  STATUS = IMG__NOITM
                  CALL ERR_REP( 'IMG1_WREXX_NOSUB', 'The creation ' //
     :                 'of non-scalar components is not allowed.',
     :                 STATUS )
               END IF

*  Check that the creation occurred successfully. If not add a little
*  more information about the error.
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL MSG_SETC( 'ITEM', ITEM )
                  CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                  CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
                  CALL ERR_REP( 'IMG1_WREXX_NOCRE', 'Unable to ' //
     :                 'create the extension item ^ITEM, in the ' //
     :                 '^EXT extension of the NDF ^NDF.',
     :                 STATUS )
               END IF
            END IF

*  If all's well then write the value.
            IF ( STATUS .EQ. SAI__OK ) THEN
               CALL DAT_PUT0<T>( LOC2, VALUE, STATUS )
               IF ( STATUS .NE. SAI__OK ) THEN

*  Conversion must have failed.
                  CALL DAT_TYPE( LOC2, TYPE, STATUS )
                  CALL MSG_SETC( 'ITEM', ITEM )
                  CALL MSG_SET<T>( 'VALUE', VALUE )
                  CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                  CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )

                  CALL MSG_SETC( 'TYPE', TYPE )
                  CALL ERR_REP( 'IMG1_WREXX_NOCRE', 'Failed to ' //
     :                 'write ''^VALUE'' to the item ^ITEM (type ' //
     :                 '^TYPE) in the ^EXT extension of the NDF ^NDF.',
     :                 STATUS )
               ELSE

*  Update the extension trace if this is a new element and the extension
*  has been initialised to use trace information (i.e. for indexing and
*  getting the number of extension items).
                  IF ( NEW .AND. ECB_XNSTK( SLOT, ESLOT ) .GT. 0 ) THEN

*  New extension item, increment the locator stack memory so this may be
*  appended.
                     ECB_XNSTK( SLOT, ESLOT ) =
     :                  ECB_XNSTK( SLOT, ESLOT ) + 1
                     CALL IMG1_CREAL( DAT__SZLOC,
     :                                ECB_XNSTK( SLOT, ESLOT ),
     :                                ECB_XPSTK( SLOT, ESLOT ), STATUS )

*  Clone the locator and store it in the stack.
                     CALL DAT_CLONE( LOC2, TMPLOC, STATUS )
                     CALL IMG1_WCEL( ECB_XNSTK( SLOT, ESLOT ),
     :                               ECB_XNSTK( SLOT, ESLOT ), TMPLOC,
     :                               %VAL( ECB_XPSTK( SLOT, ESLOT ) ),
     :                               STATUS )
                  END IF
               END IF
            END IF
         END IF

*  Return for next loop.
         GO TO 1
      END IF

*  Release the locators.
      CALL DAT_ANNUL( LOC1, STATUS )
      CALL DAT_ANNUL( LOC2, STATUS )
      END
* $Id$
