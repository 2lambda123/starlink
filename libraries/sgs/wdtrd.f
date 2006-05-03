      SUBROUTINE sgs_1WDTRD (IWKID, JSTAT)
*+
*  Name:
*     WDTRD

*  Purpose:
*     Read WDT entry into common block.

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     Internal routine

*  Arguments:
*     IWKID = INTEGER (Given)
*         SGS Workstation ID
*     JSTAT = INTEGER (Given & Returned)
*         Inherited status (if mode selected)
*         Status 0=OK (if not inherited)

*  Authors:
*     PTW: P. T. Wallace (Starlink)
*     DLT: D. L. Terrett (Starlink)
*     {enter_new_authors_here}

*  History:
*     07-SEP-1991 (PTW/DLT):
*        Modified.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Externals:
*     sgs_1HSTAT, sgs_1ERR, gns_IWSG, gns_IWCG

*  Read From Common:
*     IWTID       i()      GKS workstation ID

*  Written To Common:
*     XRES        r()      WDT - x resolution
*     YRES        r()      WDT - y resolution
*     IBLKCL      i()      WDT - block clear mechanism
*     ISPOOL      i()      WDT - workstation spooled
*     NSCLOP      l()      WDT - workstation supports no screen clear
*     open

*-

      IMPLICIT NONE

      INTEGER IWKID,JSTAT

      INCLUDE 'sgscom'

      INCLUDE 'GKS_PAR'


      CHARACTER*5 RNAME
      PARAMETER (RNAME='WDTRD')

      REAL SCALE
      CHARACTER*20 CHAR



*  Handle incoming status
      CALL sgs_1HSTAT(JSTAT)
      IF (JSTAT.NE.0) GO TO 9999

*  Fill the table with defaults
      XRES(IWKID) = 1.0
      YRES(IWKID) = 1.0
      IBLKCL(IWKID) = 0
      ISPOOL(IWKID) = 0
      NSCLOP(IWKID) = .FALSE.

*  Resolution
      JSTAT = 0
      CALL gns_IWSG(IWTID(IWKID), SCALE, JSTAT)
      IF (JSTAT.EQ.0) THEN
         XRES(IWKID) = SCALE
         YRES(IWKID) = SCALE
      END IF

*  Spooling
      JSTAT = 0
      CALL gns_IWCG(IWTID(IWKID), 'OUTPUT', CHAR, JSTAT)
      IF (JSTAT.EQ.0 .AND. CHAR.NE.'DIRECT') ISPOOL(IWKID) = 1

*  Background erase
      JSTAT = 0
      CALL gns_IWCG(IWTID(IWKID), 'CLEAR', CHAR, JSTAT)
      IF (JSTAT.EQ.0 .AND. CHAR.EQ.'SELECTIVE') IBLKCL(IWKID) = 1

*  No screen clear
      JSTAT = 0
      CALL gns_IWCG(IWTID(IWKID), 'OPEN', CHAR, JSTAT)
      IF (JSTAT.EQ.0 .AND. CHAR.EQ.'NORESET') NSCLOP(IWKID) = .TRUE.

      JSTAT = 0
9999  CONTINUE

      END
