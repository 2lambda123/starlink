      SUBROUTINE IMG1_RDEX<T>( SLOT, ESLOT, ITEM, VALUE, STATUS )
*+
*  Name:
*    IMG1_RDEXx

*  Purpose:
*    Reads a value from an extension object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL RDEXx( SLOT, ESLOT, ITEM, VALUE, STATUS )

*  Description:
*     This routine locates the HDS object ITEM in the extension (ESLOT)
*     if an NDF (SLOT). ITEM is the name of the object this may be
*     hiearchical and refer to objects in structures, provided the final
*     object is a primitive. The final primitive is converted into the
*     type of this routine and returned in VALUE.
*
*     The item may not exist in which case the VALUE argument is
*     unmodified.

*  Arguments:
*     SLOT = INTEGER (Given)
*        The slot number in the Parameter and Extension control blocks
*        of the NDF.
*     ESLOT = INTEGER (Given)
*        The slot number of the extension to be read.
*     ITEM = CHARACTER * ( * ) (Given)
*        The name of the object whose value is to be read. This may be a
*        hierarchical list of objects. The final component being the
*        primitive whose value is to be returned.
*     VALUE = <COMM> (Given and Returned)
*        The value of the HDS primitive (if located).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - There is a version of this routine for accessing items
*     of various types. Replace the "x" in the routine name by C, L, D,
*     R, or I as appropriate. If the requested item isn't of the
*     required type automatic conversion will be performed as
*     appropriate.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     21-JUL-1994 (PDRAPER):
*        Original version.
*     1-SEP-1994 (PDRAPER):
*        Now doesn't complain if the item doesn't exist.
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
      
      INCLUDE 'IMG_PCB'          ! IMG Parameter Control Block
*        PCB_INDF( IMG__MXPAR ) = INTEGER (Read)
*           NDF identifiers
      
*  Arguments Given:
      INTEGER SLOT
      INTEGER ESLOT
      CHARACTER * ( * ) ITEM
      
*  Arguments Returned:
      <TYPE> VALUE
      
*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL IMG1_INIT         ! Initialise common blocks
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Used length of string
      
*  Local Variables:
      CHARACTER * ( DAT__SZLOC ) LOC1 ! Primary locator
      CHARACTER * ( DAT__SZLOC ) LOC2 ! Secondary locator
      CHARACTER * ( 2 * DAT__SZNAM ) OBJECT ! Name of "current" object
      <LTYPE> LOCVAL             ! Local variable for extracted value
      INTEGER IAT                ! Current start position in ITEM
      INTEGER INOW               ! New position of period      
      LOGICAL MORE               ! ITEM string has more periods      
      LOGICAL YES                ! Object exists
      LOGICAL NEWVAL             ! A new value has been found
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise MORE variable for first pass.
      MORE = .TRUE.

*  No new value yet.
      NEWVAL = .FALSE.

*  Current position in the ITEM string.
      IAT = 1 

*  Clone the extension locator (so we can safely annul/re-use this
*  later).
      CALL DAT_CLONE( ECB_XLOC( SLOT, ESLOT ), LOC1, STATUS )
      
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

*  The specified item doesn't exist. Just make sure we exit.
               MORE = .FALSE.
            ELSE IF ( STATUS .EQ. SAI__OK ) THEN 

*  Now release the locator to the previous object and make this the
*  current object.
               CALL DAT_ANNUL( LOC1, STATUS )
               LOC1 = LOC2
               IAT = INOW + 2
            ELSE

*  Serious problems with finding the object.
               CALL MSG_SETC( 'ITEM', ITEM )
               CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
               CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
               CALL ERR_REP( 'IMG1_RDEX<T>_NOITEM', 'The  ' //
     :              'item ^ITEM could not be accessed in the ^EXT ' //
     :              'extension of the NDF ^NDF.', STATUS )
            END IF
         ELSE

*  No period. Final object name (or first if not hierarchical) is
*  ITEM( IAT: )
            MORE = .FALSE.
            INOW = CHR_LEN( ITEM )
            OBJECT = ITEM( IAT: INOW )
            
*  Test for the existence of the object.
            CALL IMG1_FOBJ( LOC1, OBJECT, YES, LOC2, STATUS )
            IF ( YES .AND. STATUS .EQ. SAI__OK ) THEN

*  Test that it is a primitive.
               CALL DAT_PRIM( LOC2, YES, STATUS )
               IF ( YES .AND. STATUS .EQ. SAI__OK ) THEN

*  Try to read the value.
                  CALL ERR_MARK
                  CALL DAT_GET0<T>( LOC2, LOCVAL, STATUS )

*  If this failed, report an IMG error about this.
                  IF ( STATUS .NE. SAI__OK ) THEN
                     CALL ERR_ANNUL( STATUS )
                     STATUS = IMG__CONER
                     CALL MSG_SETC( 'ITEM', ITEM )
                     CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                     CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
                     CALL ERR_REP( 'IMG1_RDEX<T>_NOITEM', 'The item ' //
     :                    '^ITEM in the ^EXT extension of ' //
     :                    'the NDF ^NDF could not be converted to ' //
     :                    'type <COMM>.', STATUS )
                  ELSE

*  New value ok.
                     NEWVAL = .TRUE.
                  END IF
                  CALL ERR_RLSE
               ELSE IF ( STATUS .EQ. SAI__OK ) THEN

*  Cannot read this. Issue an error and exit.
                  STATUS = IMG__CONER
                  CALL MSG_SETC( 'ITEM', ITEM )
                  CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
                  CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
                  CALL ERR_REP( 'IMG1_RDEX<T>_NOITEM', 'The item ' //
     :                 '^ITEM in the ^EXT extension of the NDF ^NDF ' //
     :                 'has no value.', STATUS )
               END IF
            ELSE IF ( STATUS .NE. SAI__OK ) THEN

*  Serious problems with finding the object.
               CALL MSG_SETC( 'ITEM', ITEM )
               CALL MSG_SETC( 'EXT', ECB_XNAME( SLOT, ESLOT ) )
               CALL NDF_MSG( 'NDF', PCB_INDF( SLOT ) )
               CALL ERR_REP( 'IMG1_RDEX<T>_NOITEM', 'The ' //
     :              'item ^ITEM could not be accessed in the ^EXT ' //
     :              'extension of the NDF ^NDF.', STATUS )
            END IF
         END IF

*  Return for next loop.
         GO TO 1    
      END IF

*  If we have a new value then assign the output value to it.
      IF ( NEWVAL ) THEN
         VALUE = LOCVAL
         CALL DAT_ANNUL( LOC2, STATUS )
      END IF
      CALL DAT_ANNUL( LOC1, STATUS )
      END
* $Id$
