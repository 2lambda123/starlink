      SUBROUTINE CCD1_MFREE( POINT, STATUS )
*+
*  Name:
*     CCD1_MFREE

*  Purpose:
*     Frees memory allocated by CCD1_MALL

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_MFREE( POINT, STATUS )

*  Description:
*     This routine frees memory allocated by the routine CCD1_MALL.
*     If the value of the pointer variable is -1 then all memory
*     which has been allocated is freed. No errors are reported
*     from this routine regardless of the severity, except for the case
*     when an apparent overflow in resources has occurred and has not
*     been rectified. This is a programming error.

*  Arguments:
*     POINT = INTEGER (Given)
*       Pointer to the memory which is to be deallocated. If the
*       value of this is -1 then all memory is deallocated (regardless
*       of the value of STATUS).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Either CCD1_START or CCD1_MALL should be called before this
*     routine. This initialises the common block, this is not necessary
*     if this routine is called with STATUS set.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-SEP-1992 (PDRAPER):
*        Original version.
*     12-JUL-1995 (PDRAPER):
*        Added check for overflow of resources
*     5-DEC-1997 (DSB):
*        Return with action if the supplied pointer is less than -1.
*        CCD1_MALL also changed to return a pointer of -2 if an error
*        has already occurred. Thus, this routine will now not try to
*        free memory if an error occurred before allocating it.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'CCD1_PAR'         ! CCDPACK parameterisations

*  Global Variables:
      INCLUDE 'CCD1_MEMCM'       ! Dynamic memory common block
*        CCD1_MEMCM( CCD1__MXPNT ) = INTEGER (Read and Write)
*           Array of pointers to any data which is allocated by this
*           routine. This common block is updated with the value of the
*           pointer on allocation and the value is removed on
*           deallocation (by CCD1_MFREE).
*
*        CCD1_OVER = INTEGER (Read and Write)
*           The number of calls for memory that have exceeded the
*           storage space available in the common block. This is
*           decremented by calls that do not have an associated pointer
*           slot (but only when overflow has occurred). If the -1
*           mechanism is invoked and overflow is still present a
*           warning message results.

*  Arguments Given:
      INTEGER POINT

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop variable
      LOGICAL LOCATE             ! Located pointer
*.

*  Return without action if the supplied pointer is less than -1.
      IF( POINT .LT. -1 ) RETURN

*  Begin a new error reporting context.
      CALL ERR_BEGIN( STATUS )

*  Either release the particular piece of memory requested or
*  release all memory.
      IF ( POINT .EQ. -1 ) THEN

*  Release all memory
         DO 1 I = 1, CCD1__MXPNT
            IF ( CCD1_MEMCM( I ) .NE. -1 ) THEN
               CALL PSX_FREE( CCD1_MEMCM( I ), STATUS )
               CCD1_MEMCM( I ) = -1
            END IF
 1       CONTINUE

*  If overflow is active report a problem.
         IF ( CCD1_OVER .GT. 0 ) THEN
            CALL MSG_OUT( ' ', '  CCD1_MFREE: Warning - memory '//
     :'leaks due to internal resource overflow '//
     :'(possible programming error)', STATUS )
         END IF
      ELSE

*  Try to release the memory associated with this pointer. If overflow has
*  occurred then release and decrement overflow count if the pointer isn't
*  located in the common block.
         LOCATE = .FALSE.
         DO 2 I = 1, CCD1__MXPNT
            IF ( CCD1_MEMCM( I ) .EQ. POINT ) THEN
               CALL PSX_FREE( POINT, STATUS )
               CCD1_MEMCM( I ) = -1
               LOCATE = .TRUE.
               GO TO 3
            END IF
 2       CONTINUE
 3       CONTINUE
         IF ( .NOT. LOCATE ) THEN
            CALL PSX_FREE( POINT, STATUS )
            IF ( CCD1_OVER .GT. 0 ) THEN
               CCD1_OVER = CCD1_OVER - 1
            END IF
         END IF
      END IF

*  End the error reporting context.
      CALL ERR_END( STATUS )

      END
