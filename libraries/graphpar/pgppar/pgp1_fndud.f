      SUBROUTINE PGP1_FNDUD ( PARAM, RUD, STATUS )
*+
*  Name:
*     PGP1_FNDUN

*  Purpose:
*     Get Unit descriptor from parameter name

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PGP1_FNDUD ( PARAM, RUD, STATUS )

*  Description:
*     Given the Parameter Name, the corresponding Unit descriptor (pointer 
*     within the common block) is found. If there is no corresponding unit 
*     descriptor, status PGP__UNKPA is returned.

*  Arguments:
*     PARAM = CHARACTER*(*) (Given)
*        Parameter Name
*     RUD = INTEGER (Returned)
*        Unit descriptor
*     STATUS = INTEGER (Given and returned)
*        The global status.

*  Algorithm:
*     The PARAM string is looked up in the PGPPA Common block .
*     If it is found, then the unit descriptor corresponding to
*     its position in the table is returned; otherwise, STATUS is
*     set to PGP__UNKPA.

*  Authors:
*     DLT: David Terrett (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     29-JAN-1992 (DLT):
*       Original Version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global constants:
      INCLUDE 'SAE_PAR'   ! SAE Symbolic Constants

      INCLUDE 'PAR_PAR'   ! PAR Symbolic Constants

      INCLUDE 'PGP_ERR'                 ! PGP Error codes

      INCLUDE 'pgpenv_par'              ! PGP Environment Symbolic Constants

*  Import:
      CHARACTER*(*) PARAM               ! Device Parameter Name

*  Export:
      INTEGER RUD                       ! relative unit descriptor

*  Status return:
      INTEGER STATUS                    ! status return

*  Global variables:
      INCLUDE 'pgppa_cmn'               ! PGP Parameter Table

*  Local variables:
      INTEGER I                         ! Loop index
      CHARACTER*(PAR__SZNAM) NAME       ! uppercase version of PARAM
      LOGICAL DONE                      ! loop controller
*-

      IF ( STATUS .NE. SAI__OK ) RETURN

*   Search the tables for the given name
      NAME = PARAM
      CALL CHR_UCASE ( NAME )
      DONE = .FALSE.
      I = 0
      DO WHILE ( ( .NOT. DONE ) .AND. ( I .LT. PGP__MXPAR ) )
         I = I + 1
         IF ( .NOT. PFREE(I) ) THEN
            IF ( NAME .EQ. PTNAME(I) ) THEN
               RUD = I
               DONE = .TRUE.
            ENDIF
         ENDIF
      ENDDO

      IF ( .NOT. DONE ) THEN

*      Set status 
*      This is an internal routine and the status is expected to be set
*      in many cases. The calling routines will report if necessary.
*      A report here would be unhelpful.
         STATUS = PGP__UNKPA
      ENDIF

      END
