      SUBROUTINE CCD1_FRTMP( ID, STATUS )
*+
*  Name:
*     CCD1_FRTMP

*  Purpose:
*     Frees workspace created by CCD1_MKTMP.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_FRTMP( ID, STATUS )

*  Description:
*     Use this routine when freeing in non-NDF temporary disk-file
*     space allocated by CCD1_MKTMP which may also be mapped by
*     CCD1_MPTMP. If the identifier is replaced by -1 then all
*     currently created workspace is freed and unmapped (if necessary).

*  Arguments:
*     ID = INTEGER (Given)
*        Identifier to the workspace which is to be freed.
*        (Returned by CCD1_MKTMP). If this is -1 then all workspace
*        is freed.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - this routine works regardless of the STATUS and reports no
*     errors. Always call the CCD1_MKTMP to initialise the common block
*     unless called with status set.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     25-MAY-1993 (PDRAPER):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'DAT_PAR'          ! HDS/DAT parameterisations
      INCLUDE 'CCD1_PAR'         ! CCDPACK parameterisations

*  Global Variables:
      INCLUDE 'CCD1_TMPCM'       ! Temporary workspace common block
*        CCD1_TMPPO( CCD1__MXPNT ) = INTEGER (Read and Write)
*           Array of pointers to any data which is allocated. This is
*           updated with the value of the pointer on mapping and the
*           value is removed on unmapping.
*        CCD1_TMPLO( CCD1__MXPNT ) = CHARACTER (Read and Write)
*           Array of locators to any data objects created by this
*           routine. This is updated when objects are annulled.

*  Arguments Given:
      INTEGER ID

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop variable

*.

*  Begin a new error context.
      CALL ERR_BEGIN( STATUS )

*  Check for the free everything case.
      IF ( ID .LE. 0 ) THEN

*  Free all workspace. First unmap everything
         DO 1 I = 1, CCD1__MXPNT
            IF ( CCD1_TMPPO( I ) .NE. -1 ) THEN
               CALL DAT_UNMAP( CCD1_TMPLO( I ), STATUS )
               CCD1_TMPPO( I ) =  -1
            END IF
 1       CONTINUE

*  Now erase the objects as well.
         DO 2 I = 1, CCD1__MXPNT
            IF ( CCD1_TMPLO( I ) .NE. DAT__NOLOC ) THEN
               CALL AIF_ANTMP( CCD1_TMPLO( I ), STATUS )
               CCD1_TMPLO( I ) = DAT__NOLOC
            ENDIF
 2       CONTINUE
      ELSE

*  Unmap data.
         IF ( CCD1_TMPPO( ID ) .NE. -1 ) THEN 
            CALL DAT_UNMAP( CCD1_TMPLO( ID ), STATUS )
            CCD1_TMPPO( ID ) =  -1
         END IF

*  And erase the object.
         CALL AIF_ANTMP( CCD1_TMPLO( ID ) , STATUS )
         CCD1_TMPLO( ID ) = DAT__NOLOC
      END IF

*  End the error reporting context.
      CALL ERR_END( STATUS )

      END
* $Id$
