      SUBROUTINE POL1_PTVRC( CI, STATUS )
*+
*  Name:
*     POL1_PTVRC

*  Purpose:
*     Store the current POLPACK version number as a catalogue parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_PTVRC( CI, STATUS )

*  Description:
*     This routine puts the current POLPACK version number into a
*     catalogue parameter called VERSION within the catalogue identified
*     by CI.
*
*     Note, the version number is edited into this routine when the 
*     POLPACK release is constructed. 

*  Arguments:
*     CI = INTEGER (Given)
*        A CAT identifier for the catalogue.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     6-APR-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER CI

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Used length of a string

*  Local Variables:
      CHARACTER VERS*20          ! Version string
      INTEGER VLEN               ! Used length of VERS
      INTEGER QI                 ! CAT identifier for parameter
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Save the POLPACK version number. The script which constructs the release
*  should edit in the current version number, replacing the place holder.
      VERS = "PKG_VERS"
      VLEN = CHR_LEN( VERS )

*  Create the catalogue parameter.
      CALL CAT_PPTSR( CI, 'VERSION', VERS( : VLEN ), 'POLPACK version',
     :                QI, STATUS )

*  Truncate the string to the correct length.
      CALL CAT_TATTC( QI, 'CSIZE', VLEN, STATUS )

*  Release the parameter identifier.
      CALL CAT_TRLSE( QI, STATUS )

      END
