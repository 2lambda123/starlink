      SUBROUTINE CCD1_GTLIG( NDFS, ITEM, PARNAM, MINOPN, MAXOPN, NOPEN,
     :                       FIOGR, NDFGR, NNOLIS, NLGR, STATUS )
*+
*  Name:
*     CCD1_GTLIG

*  Purpose:
*     Gets a GRP group of validated (formatted) file names.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_GTLIG( NDFS, ITEM, PARNAM, MINOPN, MAXOPN, NOPEN,
*                      FIOGR, NDFGR, NNOLIS, NLGR, STATUS )

*  Description:
*     This routine creates a GRP group of filenames. The files are
*     tested for existence before entry into the group. The names of
*     the files may be accessed in two different (exclusive) fashions.
*     If the NDFS argument is set true then it is assumed that the
*     names of the files are stored within the CCDPACK extensions of a
*     list of NDFs. The name of the file to be actually returned is
*     stored in
*
*         ndf_name.more.ccdpack.ITEM
*
*     If NDFS is true then a GRP group identifier is also returned
*     for a group containing the NDF names (NDFGR).
*     
*     If NDFS is false then it is assumed that the names accessed
*     through the ADAM parameters PARNAM using GRP are just the exact
*     names of the files.  All files are then opened using FIO_OPEN to
*     test for their existence. 
*
*     If an extension does not exist or the file cannot be opened then 
*     an error is reported and status is set.  If NDFs is true and the
*     CCDPACK extension exists, but no ITEM is in it, then a message is
*     printed and status is not set.  In this case the list in question
*     is not added to the GRP group.

*  Arguments:
*     NDFS = LOGICAL (Given)
*        Whether the names of the files to be opened are stored with the
*        extensions of NDFs are not. It true the input names are
*        expanded into an NDG group.
*     ITEM = CHARACTER * ( * ) (Given)
*        Only used if NDFS is true. The name of the extension item
*        with contains the file name.
*     PARNAM = CHARACTER * ( * ) (Given)
*        The ADAM parameter name via which the list of file names is to
*        be accessed.
*     MINOPN = INTEGER (Given)
*        The minimum number of files which need to be opened.
*     MAXOPN = INTEGER (Given)
*        The maximum number of files which can be opened.
*     NOPEN = INTEGER (Returned)
*        The number of files which were opened (size of FIOGR and NDFGR).
*     FIOGR = INTEGER (Returned)
*        A GRP group identifier for the names of the files which have
*        opened. This group is intended for use as a modification group.
*     NDFGR = INTEGER (Returned)
*        An NDG group identifier for the names of the NDFs from which
*        the filenames were obtained.
*     NNOLIS = INTEGER (Returned)
*        The number of NDFs which were specified by the user but have
*        no associated position list (size of NLGR).
*     NLGR = INTEGER (Returned)
*        An NDG group identifier for the names of NDFs which were 
*        specified by the user, but have no associated position list.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  The calling routine must close all the files which are opened
*     before exit. 
*     -  The calling routine must annul the group identifiers before exit.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     22-JUL-1992 (PDRAPER):
*        Original version.
*     28-JUL-1992 (PDRAPER):
*        Added minimum number of input files option.
*     22-JAN-1993 (PDRAPER):
*        Changed to look for names in NDF extensions.
*     25-JAN-1993 (PDRAPER):
*        Changed to not return the FIO identifiers.
*     3-MAR-1997 (PDRAPER):
*        Removed LOC argument and associated code from IRG_NDFEX call.
*     26-APR-1999 (MBT):
*        Modified so that failing to find ITEM in the CCDPACK extension
*        is no longer fatal.
*     29-JUN-2000 (MBT):
*        Replaced use of IRH/IRG with GRP/NDG.
*     16-MAR-2001 (MBT):
*        Added NNOLIS and NLGR arguments.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS/DAT constants
      INCLUDE 'GRP_PAR'          ! Standard GRP constants

*  Arguments Given:
      LOGICAL NDFS
      CHARACTER * ( * ) ITEM
      CHARACTER * ( * ) PARNAM
      INTEGER MINOPN
      INTEGER MAXOPN

*  Arguments Returned:
      INTEGER NOPEN
      INTEGER NNOLIS
      INTEGER FIOGR
      INTEGER NDFGR
      INTEGER NLGR

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( GRP__SZNAM ) FNAME ! Filename
      CHARACTER * ( GRP__SZNAM ) NNAME ! NDF name
      INTEGER FD                 ! FIO file descriptor
      INTEGER I                  ! Loop variable
      INTEGER INGRP              ! Dummy GRP identifier
      INTEGER NDF1GR             ! GRP identifier for group of all PARNAM NDFs
      INTEGER NDFID              ! NDF identfier
      INTEGER NRET               ! Number of names in group
      LOGICAL OK                 ! Flag showing extension ok

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Access the lists of names. This may be a list of NDF names (which may
*  include wildcards) or just a straight-forward list of ordinary
*  file-names.
      IF ( NDFS ) THEN

*  Access a list of NDF names.
         CALL CCD1_NDFGL( PARNAM, MINOPN, MAXOPN, NDF1GR, NRET, STATUS )
      ELSE

*  Not a list of NDFs, just get a group of names.
         INGRP = GRP__NOID
         CALL CCD1_STRGR( PARNAM, INGRP, MINOPN, MAXOPN, FIOGR, NRET,
     :                    STATUS )
         CALL MSG_SETI( 'NOPEN', NRET )
         CALL MSG_SETC( 'PARNAM', PARNAM )
         IF ( NRET .EQ. 1 ) THEN 
            CALL MSG_OUT( ' ',
     :'  ^NOPEN name accessed using parameter %^PARNAM', STATUS )
         ELSE
            CALL MSG_OUT( ' ',
     :'  ^NOPEN names accessed using parameter %^PARNAM', STATUS )
         END IF
      END IF
      IF ( STATUS .NE. SAI__OK ) GO TO 99

*  If all's well then proceed to either open the files, if NDFS is
*  false or start looking for the names in the NDF extensions.
      IF ( NDFS ) THEN

*  Initialise number of names successfully entered in the group.
         NOPEN = 0
         NNOLIS = 0

*  Create GRP groups to contain the name strings.
         CALL GRP_NEW( 'CCDPACK:FILELIST', FIOGR, STATUS )
         CALL GRP_NEW( 'CCDPACK:NDFLIST', NDFGR, STATUS )
         CALL GRP_NEW( 'CCDPACK:NOLIST', NLGR, STATUS )

*  Open each NDF in turn and locate the required name.
         DO 2 I = 1, NRET
            CALL NDG_NDFAS( NDF1GR, I, 'UPDATE', NDFID, STATUS )

*  Get the NDF name and file name.
            CALL GRP_GET( NDF1GR, I, 1, NNAME, STATUS )
            CALL CCG1_FCH0C( NDFID, ITEM, FNAME, OK ,STATUS )  
            IF ( .NOT. OK .AND. STATUS .EQ. SAI__OK ) THEN

*  Cannot locate the named extension item.  Add this name to the group
*  of NDFs with no associated list.
               CALL GRP_PUT( NLGR, 1, NNAME, 0, STATUS )
               NNOLIS = NNOLIS + 1

*  Report that this NDF will be ignored and add it to the group of 
*  NDFs with no associated list.
               CALL MSG_SETC( 'NDF', NNAME )
               CALL CCD1_MSG( ' ',
     :'  There is no associated list for NDF ^NDF.', STATUS )
            ELSE

*  Enter the file name and the NDF name into the new groups, appending 
*  to the end (0).
               CALL GRP_PUT( FIOGR, 1, FNAME, 0, STATUS )
               CALL GRP_PUT( NDFGR, 1, NNAME, 0, STATUS )
               NOPEN = NOPEN + 1
            END IF

*  Release the NDF.
            CALL NDF_ANNUL( NDFID, STATUS )
            IF ( STATUS .NE. SAI__OK ) GO TO 99
 2       CONTINUE

*  Annul the original NDF group identifier, since it is no longer required.
         CALL CCD1_GRDEL( NDF1GR, STATUS )
      ELSE

*  If position lists are given directly, the number to consider must be 
*  the number in PARNAM.
         NOPEN = NRET
         NNOLIS = 0
         NDFGR = GRP__NOID
         NLGR = GRP__NOID
      END IF

*  Now at stage were we have a group of names which may belong to a
*  list of formatted files. Try to open them one by one, stop if one
*  does not exist.
      DO 3 I = 1, NOPEN
         CALL GRP_GET( FIOGR, I, 1, FNAME, STATUS )

*  Try to open the file.
         CALL FIO_OPEN( FNAME, 'READ', 'LIST', 0, FD, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN

*  Everything ok - file exists. Now close it.
            CALL FIO_CLOSE( FD, STATUS )
         ELSE

*  Failed to open the file. Stop and issue error.
            STATUS = SAI__ERROR
            CALL MSG_SETC( 'FNAME', FNAME )
            CALL ERR_REP( 'CCD1_GTLIS_FERR',
     :         '  Failed to open file ^FNAME', STATUS )
         END IF
 3    CONTINUE

*  Ensure that we have an acceptable number of lists.  We may have 
*  arrived here without that if an acceptable number of NDFs were
*  supplied but they did not all have associated lists.
      IF ( NOPEN .LT. MINOPN ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NOPEN', NOPEN )
         CALL MSG_SETI( 'MINOPN', MINOPN )
         CALL ERR_REP( 'CCD1_GTLIG_TOOFEW', 'Only ^NOPEN lists were'//
     :' supplied - need at least ^MINOPN', STATUS )
      ELSE IF ( NOPEN .GT. MAXOPN ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NOPEN', NOPEN )
         CALL MSG_SETI( 'MAXOPN', MAXOPN )
         CALL ERR_REP( 'CCD1_GTLIG_TOOMANY', '^NOPEN lists were'//
     :' supplied - no more than ^MAXOPN required', STATUS )
      END IF

*  Exit.
 99   CONTINUE
      END
* $Id$
