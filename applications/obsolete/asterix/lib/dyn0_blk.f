      BLOCK DATA DYN0_BLK
*+
*  Name:
*     DYN0_BLK

*  Purpose:
*     Initialise DYN common block

*  Language:
*     Starlink Fortran

*  Type of Module:
*     BLOCK DATA

*  Description:
*     Set the initialised flag to false so that DYN will be initialised
*     if required. Note that the file sequence number is set here rather
*     than in DYN0_INIT so that sequence numbers increase even if
*     DYN_CLOSE is called, followed by a DYN_INIT (eg. in a monolith).

*  Notes:
*     {routine_notes}...

*  Side Effects:
*     {routine_side_effects}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     DYN Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/dyn.html

*  Keywords:
*     package:dyn, usage:private, common, initialisation

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     20 Mar 1995 (DJA):
*        Original version.
*     21 Dec 1995 (DJA):
*        Added diagnostic flag
*     {enter_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Variables:
      INCLUDE 'DYN_CMN'
*       DYN_ISINIT = LOGICAL (returned)
*         DYN system is initialised?
*       DYS_DIAG = LOGICAL (returned)
*         Diagnnostics on?
*       DYS_ISEQ = INTEGER (returned)
*         File sequence flag

*  Global Data:
      DATA DYN_ISINIT / .FALSE. /
      DATA DYS_DIAG / .FALSE. /
      DATA DYS_ISEQ / 1 /
*.

      END
