      SUBROUTINE GKS1_DEAS ( WKID, STATUS )
*+
*  Name:
*     GKS1_DEAS

*  Purpose:
*     De-activate and close GKS Workstation

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL GKS1_DEAS ( WKID, STATUS )

*  Description:
*     The device specified by the workstaton identifier is deassigned, and
*     forgotten by the GKS library.

*  Algorithm:
*     Get the GKS Workstation associated with the zone and close it.

*  Arguments:
*     WKID = INTEGER (Given)
*        A Variable to contain the Workstation Identifier.
*     STATUS = INTEGER (Given and returned)
*        The global status.

*  Authors:
*     SLW: Sid Wright (UCL)
*     BDK: Dennis Kelly (ROE)
*     AJC: Alan Chipperfield (Starlink, RAL)
*     DLT: David Terrett (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     11-OCT-1983 (SLW):
*        Starlink Version.
*     06-MAR-1985 (BDK):
*        ADAM version
*     26-FEB-1986 (AJC):
*        GKS 7.2 version
*     089-JAN-1992 (DLT):
*        Reformat comments and change name to GKS1_DEAS
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global constants :
      INCLUDE 'SAE_PAR'        ! SAE Symbolic Constants
      INCLUDE 'GKS_PAR'        ! GKS internal parameters

*  Arguments Given::
      INTEGER WKID                      ! Workstation-ID

*  Status:
      INTEGER STATUS                    ! status return

*  Local variables :
      INTEGER ISTAT                     ! temporary status
      INTEGER ERRIND                    ! inquiry error indicator
      INTEGER IFACT                     ! If active

*.

      ISTAT = STATUS
      STATUS = SAI__OK

*   See if Workstation is active
      CALL GQWKS( WKID, ERRIND, IFACT)
      IF ( IFACT.EQ.GACTIV ) CALL GDAWK( WKID )

*   Close Workstation
      CALL GCLWK( WKID )
      CALL GKS_GSTAT ( STATUS )

      IF ( ISTAT .NE. SAI__OK ) THEN
         STATUS = ISTAT
      ENDIF

      END
