      SUBROUTINE SUBPAR_TSKNM( TSKNAM, PFNAM, IFNAM, IFC, STATUS )
*+
*  Name:
*     SUBPAR_TSKNM

*  Purpose:
*     To obtain the full names of the interface file and parameter
*     file associated with the task.
*     This routine is expected to be machine dependent

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_TSKNM( TSKNAM, PFNAM, IFNAM, IFC, STATUS )

*  Description:
*     The routine finds the full name of the executable image being
*     run then constructs from it the parameter file name, using the
*     directory defined by the SUBPAR_ADMUS routine.
*     It then searches the ADAM_IFL path to find the first occurrence
*     of a .IFL or .IFC file with the same name.

*  Arguments:
*     TSKNAM = CHARACTER*(*) (Returned)
*        The name of the task (derived from the executable name)
*     PFNAM = CHARACTER*(*) (Returned)
*        The full name of the associated parameter file
*     IFNAM = CHARACTER*(*) (Returned)
*        The full name of the interface file
*     IFC = LOGICAL (Returned)
*        TRUE if the interface module is an IFC.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  [optional_subroutine_items]...
*  Authors:
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     11-JUL-1991 (AJC):
*        Original version.
*     10-FEB-1992 (AJC):
*        Use SUBPAR_ADMUS.
*     12-FEB-1992 (AJC):
*        Correct access mode for interface files
*     05-MAR-1992 (AJC):
*        Improve interface file not found report
*     12-MAR-1995 (AJC):
*        Trap error from SUBPAR_ADMUS now it tries to create directory
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'SUBPAR_ERR'       ! SUBPAR error values

*  Arguments Returned:
      CHARACTER*(*) TSKNAM
      CHARACTER*(*) PFNAM
      CHARACTER*(*) IFNAM
      LOGICAL IFC

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL CHR_LEN
      INTEGER CHR_LEN            ! Used lenth of string
      EXTERNAL STRING_IANYR
      INTEGER STRING_IANYR       ! Index search backwards
      EXTERNAL ACCESS
      INTEGER ACCESS             ! File access

*  Local Variables:
      CHARACTER*(256) ARGV0      ! Argument 0 of command
      CHARACTER*(256) EXENAM     ! Full executable image name
      CHARACTER*(256) ADMUSR     ! ADAM_USER directory
      INTEGER EXELEN             ! Used length of EXENAM
      INTEGER AULEN              ! Length of ADAM_USER directory name
      INTEGER STNM               ! Start of file name in description
      INTEGER ENDNM              ! End of file name in description
      INTEGER IND                ! Index for FIFIL
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
	
*  Set error reportin level
      CALL EMS_MARK

*  Get the command name
      CALL GETARG (0, ARGV0)

*  If it is a full pathname - use it as is
      IF (INDEX (ARGV0, '/') .NE. 0) THEN
         EXENAM = ARGV0
            	
*  Otherwise find the full name of the executable
      ELSE
         CALL SUBPAR_FIFIL ( 'PATH', ARGV0, ' ', 'x',
     :    EXENAM, IND, STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL EMS_REP( 'SUP_TSKNM1',
     :      'Failed to find executable image name', STATUS )
         ENDIF

      ENDIF

      IF ( STATUS .EQ. SAI__OK ) THEN         
*     Find the name part of the file description
         EXELEN = CHR_LEN( EXENAM )
         STNM = STRING_IANYR( EXENAM(1:EXELEN), '/' ) + 1
         ENDNM = STRING_IANYR( EXENAM(STNM:EXELEN), '.' ) - 1
*     Adjust ENDNM to absolute position, allowing for case of no '.' in
*     name.
         IF ( ENDNM .LE. 0 ) THEN
            ENDNM = EXELEN
         ELSE
            ENDNM = STNM + ENDNM
         ENDIF

*     Save the task name
         TSKNAM = EXENAM(STNM:ENDNM)

*     Construct the parameter file name
*     First find the directory to be used
         CALL SUBPAR_ADMUS ( ADMUSR, AULEN, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            PFNAM = ADMUSR(1:AULEN) // TSKNAM

*        Find the interface module
*        First look along path ADAM_IFL for a .ifc or .ifl with read
*        access
            CALL SUBPAR_FIFIL ( 'ADAM_IFL', TSKNAM, '.ifc!.ifl', 'r',
     :       IFNAM, IND, STATUS )

*        If not found, look in same directory as executable
            IF ( STATUS .NE. SAI__OK ) THEN

*           First annul the error messages from _FIFIL
               CALL EMS_ANNUL ( STATUS )
               IF ( ACCESS( EXENAM(1:ENDNM)//'.ifc','r') .EQ. 0 ) THEN
*              An IFC is found
                  IFC = .TRUE.
                  IFNAM = EXENAM(1:ENDNM)//'.ifc'

               ELSE IF ( ACCESS( EXENAM(1:ENDNM)//'.ifl','r') .EQ. 0 )
     :         THEN
*              An IFL is found
                  IFC = .FALSE.
                  IFNAM = EXENAM(1:ENDNM)//'.ifl'

               ELSE
*              No interface module found
                  STATUS = SUBPAR__IFNF
                  CALL EMS_SETC( 'TSKNAM', TSKNAM )
                  CALL EMS_REP( 'SUP_TSKNM1',
     :            'Interface file for ^TSKNAM not found', STATUS )

               ENDIF

            ELSE
*           Interface module was found along ADAM_IFL - set IFC appropriately
               IF ( IND .EQ. 1 ) THEN
                  IFC = .TRUE.
               ELSE
                  IFC = .FALSE.
               ENDIF

            ENDIF
            
         ENDIF

      ENDIF
      
      CALL EMS_RLSE

      END
