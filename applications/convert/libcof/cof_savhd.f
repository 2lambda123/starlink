      SUBROUTINE COF_SAVHD( FUNIT, STATUS )
*+
* Name:
*     COF_SAVHD

*  Purpose:
*     Save a FITS header

*  Language:
*     Fortran 77

*  Invocation:
*     CALL COF_SAVHD( FUNIT, STATUS )

*  Description:
*     Saves the FITS header specified by the given FITS unit as a
*     elements of a CHARACTER*80 array, space for which is obtained by
*     PSX_MALLOC.
*     The number of header cards (NHEAD) and a pointer to the CHARACTER
*     array (H0_PTR) are saved in common block /F2NDF2_CMN/.
*     NPHEAD is also used as a flag that a header has been saved
*     and memory has been allocated.

*  Arguments:
*     FUNIT = INTEGER (Given)
*        Logical unit number associated with a FITS file.
*     STATUS = INTEGER (Given and returned)
*        The global status.

*  Notes:
*     -  {noted_item}
*     [routine_notes]...

*  External Routines Used:
*     CFITSIO:
*        FTGHSP
*        FTGREC
*     PSX:
*        PSX_MALLOC
*     CNF:
*        CNF_PVAL
*

*  Implementation Deficiencies:
*     -  {deficiency}
*     [routine_deficiencies]...

*  References:
*     -  {reference}
*     [routine_references]...

*  Keywords:
*     {routine_keywords}...

*  Copyright:
*     Copyright (C) 2000 Central Laboratory of the Research Councils

*  Authors:
*     AJC: Alan Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     14-AUG-2000 (AJC):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     -  {description_of_bug}
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'CNF_PAR'         ! CNF definitions
      
*  Arguments Given:
      INTEGER FUNIT
      
*  Arguments Given and Returned:
      
*  Arguments Returned:
      INTEGER BLOCSZ
      INTEGER EXTN
      
*  Status:
      INTEGER STATUS            ! Global status

*  External References:
      
*  Local Constants:
      INTEGER   FITSOK           ! Value of good FITSIO status
      PARAMETER( FITSOK = 0 )

      INTEGER HEDLEN             ! FITS header length
      PARAMETER( HEDLEN = 80 )

*  Global Variables:
      INCLUDE 'F2NDF2_CMN'
      
*  Local Variables:
      INTEGER IHD                 ! Header card number
      INTEGER ISV                 ! Saved card number
      INTEGER KEYADD              ! Unused argument of FTGHSP
      INTEGER FSTAT               ! FITS status
      CHARACTER*(HEDLEN) HEADER   ! Individual header card
      LOGICAL MEMGOT              ! Whether memory got
      
*  Local Data:
      
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise FITS status
      FSTAT = FITSOK

*  Get the number of header cards
      CALL FTGHSP( FUNIT, NPHEAD, KEYADD, FSTAT )
      IF ( FSTAT .EQ. FITSOK ) THEN

*  Obtain memory
         CALL PSX_MALLOC( NPHEAD*HEDLEN, H0_PTR, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            MEMGOT = .TRUE.
            ISV = 0
            DO IHD = 1, NPHEAD
               CALL FTGREC( FUNIT, IHD, HEADER, FSTAT )
               IF ( FSTAT .NE. FITSOK ) THEN
                  STATUS = SAI__ERROR
                  CALL MSG_SETI( 'NH', NPHEAD )
                  CALL MSG_SETI( 'IH', IHD )
                  CALL ERR_REP( 'COF_SAVHD_REC',
     :             'Failed to read header record ^IH of ^NH',
     :             STATUS )
                  GO TO 999
               ELSE
* Only save required keywords
                  IF( ( HEADER(1:8) .EQ. 'SIMPLE' )
     :            .OR.( HEADER(1:8) .EQ. 'BITPIX' )
     :            .OR.( HEADER(1:5) .EQ. 'NAXIS' )
     :            .OR.( HEADER(1:8) .EQ. 'EXTEND' )
     :            .OR.( HEADER(1:8) .EQ. 'NEXTEND' )
     :            .OR.( HEADER(1:8) .EQ. 'CHECKSUM' )
     :            .OR.( HEADER(1:8) .EQ. 'HISTORY' )
     :            .OR.( HEADER(1:8) .EQ. 'COMMENT' ) ) THEN
                     CONTINUE

                  ELSE
                     ISV = ISV + 1
                     CALL COF_COPHD( 
     :                 HEADER, ISV, %VAL(CNF_PVAL(H0_PTR)),
     :                 STATUS )
                  END IF  ! Required header
               END IF  ! Got header OK
            END DO  ! For each header

         ELSE
            CALL ERR_REP( 'COF_SAVHD_MEM',
     :       'Failed to get memory for primary headers',
     :       STATUS )
            NPHEAD = 0

         END IF  ! Got memory OK

      ELSE
         STATUS = SAI__ERROR
         CALL ERR_REP( 'COF_SAVHD_MEM',
     :    'Failed to get memory for primary headers', STATUS )
         
      END IF  ! Got number of headers OK

999   CONTINUE
      IF ( STATUS .EQ. SAI__OK ) THEN
* Set NPHEAD in common to the number of saved header cards
         NPHEAD = ISV

      ELSE
* In the event of an error, clear the saved data
         NPHEAD = 0
         IF ( MEMGOT ) CALL PSX_FREE( H0_PTR, STATUS )
         
      END IF
         
      END
