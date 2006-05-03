      SUBROUTINE sgs_OPEN (WKSTN, IZONID, JSTAT)
*+
*  Name:
*     OPEN

*  Purpose:
*     Open SGS with logical unit 6 for errors, and one workstation.

*  Language:
*     Starlink Fortran 77

*  Description:
*     When the "Starlink" GKS error handler is being used, all errors are
*     sent to the Starlink error reporting system, and the error channel
*     passed to GOPKS is never used - except that the channel may be
*     opened which causes an empty file to be created on some systems.
*     This can be avoided by using a channel which is pre-connected to the
*     terminal (usually 6).  This may not be appropriate on all systems.

*  Arguments:
*     WKSTN = CHAR (Given)
*         Workstation name
*     IZONID = INTEGER (Returned)
*         Zone identifier
*     JSTAT = INTEGER (Returned)
*         Status: 0=OK

*  Authors:
*     PTW: P. T. Wallace (Starlink)
*     DLT: D. L. Terrett (Starlink)
*     {enter_new_authors_here}

*  History:
*     14-SEP-1991 (PTW/DLT):
*        Modified.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Externals:
*     sgs_INIT, sgs_OPNWK

*-

      IMPLICIT NONE

      CHARACTER*(*) WKSTN
      INTEGER IZONID,JSTAT


*  Initialise SGS
      CALL sgs_INIT(6,JSTAT)

*  Open workstation
      CALL sgs_OPNWK(WKSTN,IZONID,JSTAT)

      END
