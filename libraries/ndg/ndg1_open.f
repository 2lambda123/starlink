      SUBROUTINE NDG1_OPEN( NAME, PLACE, STATUS )
*+
*  Name:
*     NDG1_OPEN

*  Purpose:
*     Get an NDF place holder for a new NDF

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDG1_OPEN( NAME, PLACE, STATUS )

*  Description:
*     This routine returns an NDF place holder for a new NDF, ensuring that 
*     any HDS container file or structures required to created the named 
*     NDF exist. If they do not exist, they are created.

*  Arguments:
*     NAME = CHARACTER * ( * ) (Given)
*        The full HDS path to the NDF to be created.
*     PLACE = INTEGER (Returned)
*        The place holder.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-DEC-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS constants.
      INCLUDE 'NDF_PAR'          ! NDF constants.

*  Arguments Given:
      CHARACTER NAME*(*)
      
*  Arguments Returned:
      INTEGER PLACE

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER INDF               ! Dummy argument

*.

*  Initialise 
      PLACE = NDF__NOPL

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Start a new error context
      CALL ERR_BEGIN( STATUS )

*  Attempt to get a place holder for the named NDF.
      CALL NDF_OPEN( DAT__ROOT, NAME, 'WRITE', 'NEW', INDF, PLACE, 
     :               STATUS )

*  If an error was reported, annul the error, check that the structure
*  required to contain the NDF exists, and try to get the place holder
*  again.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_ANNUL( STATUS )
         CALL NDG1_CRPTH( NAME, STATUS )
         CALL NDF_OPEN( DAT__ROOT, NAME, 'WRITE', 'NEW', INDF, PLACE, 
     :                  STATUS )
      END IF

*  End the error context
      CALL ERR_END( STATUS )

      END
