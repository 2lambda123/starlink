      BLOCK DATA PSF_BLK
*+
*  Name:
*     PSF_BLK

*  Purpose:
*     PSF Block Data Initialisation

*  Language:
*     Starlink Fortran 77

*  Description:
*     Initialise the PSF_CMN Common Block to force activation of PSF subsystem.

*  Authors:
*     DJA: David J. Allan (ROSAT,University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     29-Jan-1994 (DJA):
*        Original
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              	! No implicit typing

*  Global constants:
      INCLUDE 'PSF_PAR'                 ! Psf system constants

*  Global Variables:
      INCLUDE 'PSF_CMN'			! PSF Initialisation Switches
*        PSFAUTO = LOGICAL (Returned)
*           Psf load automatic?

*  Global data:
      DATA PSFAUTO/.FALSE./
*.

      END
