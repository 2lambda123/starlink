      SUBROUTINE ERASE( STATUS )
*+
*  Name:
*     ERASE

*  Purpose:
*     Erases an HDS object.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ERASE( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Usage:
*     erase object

*  Description:
*     This routine erases a specified HDS object or container file.  If
*     the object is a structure, then all the structure's components
*     (and sub-components, etc.) are also erased.  If a slice or cell of
*     an array is specified, then the entire array is erased.

*  ADAM Parameters:
*     OBJECT = UNIV (Write)
*        The HDS object or container file to be erased.
*     OK = _LOGICAL (Read)
*        This parameter is used to seek confirmation before an object
*        is erased.  If a TRUE value is given, then the HDS object will
*        be erased.  If a FALSE value is given, then the object will not
*        be erased and a message will be issued to this effect.

*  Examples:
*     erase horse
*        This erases the HDS container file called horse.sdf.
*     erase fig123.axis
*        This erases the AXIS component of the HDS file called
*        fig123.sdf.  If AXIS is a structure, all its components are
*        erased too.
*     erase fig123.axis(1).label
*        This erases the LABEL component within the first element of
*        the AXIS structure of the HDS file called fig123.sdf.
*     erase $AGI_USER/agi_restar.agi_3200_1
*        This erases the AGIDEV_3200_1 structure of the HDS file called
*        $AGI_USER/agi_restar.sdf.

*  Related Applications:
*     Figaro: CREOBJ, DELOBJ, RENOBJ.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     5-APR-1990 (RFWS):
*        Original version.
*     6-APR-1990 (RFWS):
*        Added workaround for HDS top-level locator problem.
*     1992 February 7 (MJC):
*        Added Usage and Examples items.
*     1995 April 24 (MJC):
*        Made usage and examples lowercase.  Added Related Applications.
*        Sorted the variable declarations.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ constants
      INCLUDE 'FIO_PAR'          ! FIO_ public constants
      INCLUDE 'PAR_ERR'          ! PAR_ error codes

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Significant length of a string

*  Local Constants:
      INTEGER SZPATH             ! Length of HDS path name
      PARAMETER ( SZPATH = 128 )

*  Local Variables:
      CHARACTER * ( FIO__SZFNM ) FILE ! HDS container file name
      CHARACTER * ( DAT__SZLOC ) LOC ! Object locator
      CHARACTER * ( DAT__SZLOC ) LOCP ! Parent object locator
      CHARACTER * ( DAT__SZNAM ) NAME ! Object name
      INTEGER NC                 ! Number of characters in name
      INTEGER NLEV               ! Number of HDS levels
      LOGICAL OK                 ! Confirmation flag
      CHARACTER * ( SZPATH ) PATH ! HDS path name

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Open an error context, to permit annulling of errors which may occur.
      CALL ERR_MARK

*  Obtain a locator to the object to be erased.
      LOC = ' '
      CALL DAT_EXIST( 'OBJECT', 'WRITE', LOC, STATUS )

*  If the object does not exist, then annul the error and make a new
*  error report.
      IF ( STATUS .EQ. PAR__ERROR ) THEN
         LOC = ' '
         CALL ERR_ANNUL( STATUS )
         STATUS = SAI__ERROR
         CALL ERR_REP( 'ERASE_NOOBJ',
     :   'The object ''$OBJECT'' does not exist or is inaccessible.',
     :                 STATUS )

*  If the object exists, obtain its path name and define a prompt to
*  confirm if it should be erased.
      ELSE IF ( STATUS .EQ. SAI__OK ) THEN
         CALL HDS_TRACE( LOC, NLEV, PATH, FILE, STATUS )
         NC = MAX( 1, CHR_LEN( PATH ) )
         CALL PAR_PROMT( 'OK',
     :   'The HDS object ' // PATH( : NC ) // ' is to be erased. OK ?',
     :                   STATUS )

*  Seek confirmation.
         CALL PAR_GET0L( 'OK', OK, STATUS )

*  If an error occurred, then annul the locator but take no further
*  action.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL DAT_ANNUL( LOC, STATUS )
            LOC = ' '

*  Acknowledge non-erasure.
         ELSE IF ( .NOT. OK ) THEN
            CALL MSG_OUT( 'ERASE_NO',
     :      'Object ' // PATH( : NC ) // ' not erased.', STATUS )

*  If it is a top-level object, then annul the locator and obtain a new
*  top-level locator by re-opening the container file.

*  (N.B. This is a workaround for what may be an HDS problem: the
*  initial locator cannot be used because HDS appears not to have
*  incremented the top-level locator count to include it.  Marking the
*  file for deletion through this locator therefore causes it to be
*  erased immediately, which subsequently causes problems for the
*  parameter system which still has a top-level locator to the file.)
         ELSE
            IF ( NLEV .LE. 1 ) THEN
               CALL DAT_ANNUL( LOC, STATUS )
               LOC = ' '
               CALL HDS_OPEN( FILE, 'WRITE', LOC, STATUS )

*  Mark the file for deletion through HDS.
               CALL HDS_ERASE( LOC, STATUS )
               LOC = ' '

*  If it is not a top level object, then obtain its name and obtain a
*  locator to its parent.
            ELSE
               CALL DAT_NAME( LOC, NAME, STATUS )
               LOCP = ' '
               CALL DAT_PAREN( LOC, LOCP, STATUS )

*  Annul the object's locator and erase it.
               CALL DAT_ANNUL( LOC, STATUS )
               LOC = ' '
               CALL DAT_ERASE( LOCP, NAME, STATUS )

*  Annul the parent's locator.
               CALL DAT_ANNUL( LOCP, STATUS )
               LOCP = ' '
            END IF
         END IF
      END IF

*  Close the error context.
      CALL ERR_RLSE

*  If an error occurred, then add context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ERASE_ERR',
     :   'ERASE: Error erasing HDS object.', STATUS )
      END IF

      END
