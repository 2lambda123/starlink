      SUBROUTINE NDG_ENDPV( STATUS )
*+
*  Name:
*     NDG_ENDPV

*  Purpose:
*     End an NDF provenance block.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDG_ENDPV( STATUS )

*  Description:
*     This routine should be called to mark the end of an NDF 
*     provenance block. The block should have been started by a 
*     matching call to NDG_BEGPV. Note, provenance blocks must 
*     not be nested.
*
*     During a provenance block, a list is maintained of all the 
*     existing NDFs that have been read (either in read or update 
*     mode) during the block. Another list is maintained of all 
*     the NDFs that have been written (either existing NDFs accessed 
*     in update mode or new NDFs) during the block.
*
*     When the block ends, the provenance information within each 
*     NDF in the second may be modified to include all the NDFs in the
*     first list as parents. Whether or not this occurs is controlled by
*     the AUTOPROV environment variable. If AUTOPROV is set to '1' then
*     the input NDFs are added to the provenance information in the
*     output NDF. If AUTOPROV is set to anything other than '1' then the
*     output provenance is not updated. If AUTOPROV is not set at all, 
*     then the output provenance will be updated only if one or more of 
*     the input NDFs contains a PROVENANCE extension.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2007 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This programme is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*     
*     This programme is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE.  See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this programme; if not, write to the Free Software
*     Foundation, Inc., 59, Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     31-OCT-2007 (DSB):
*        Original version.
*     5-NOV-2007 (DSB):
*        - Allow propagation of provenance to be controlled by the AUTOPROV 
*        environment variable.
*        - Annul errors and continue if any NDF cannot be opened.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'DAT_PAR'          ! DAT constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'PSX_ERR'          ! PSX error constants

*  Global Variables:
      INTEGER RDGRP              ! Group holding input NDFs
      INTEGER WRGRP              ! Group holding output NDFs
      COMMON /NDG_PRV/ RDGRP, WRGRP

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL NDG1_HNDLR

*  Local Variables:
      CHARACTER AUTOPV*10
      CHARACTER RDNDF*(GRP__SZNAM)
      CHARACTER WRNDF*(GRP__SZNAM)
      INTEGER INDF1
      INTEGER INDF2
      INTEGER IR
      INTEGER IW
      INTEGER NR
      INTEGER NW
      INTEGER PLACE
      INTEGER WRGRP2
      INTEGER RDGRP2
      LOGICAL INPRV
      LOGICAL THERE
*.

*  Begin a new error reporting context (we want to clean up even if an
*  error has occurred).
      CALL ERR_BEGIN( STATUS )

*  Indicate that the routine NDG1_HNDLR should no longer be called 
*  whenever an NDF is opened or closed.
      CALL NDF_HNDLR( "READ_EXISTING_NDF", NDG1_HNDLR, .FALSE., STATUS )
      CALL NDF_HNDLR( "WRITE_EXISTING_NDF", NDG1_HNDLR, .FALSE., 
     :                STATUS )
      CALL NDF_HNDLR( "UPDATE_EXISTING_NDF", NDG1_HNDLR, .FALSE., 
     :                STATUS )
      CALL NDF_HNDLR( "OPEN_NEW_NDF", NDG1_HNDLR, .FALSE., STATUS )
      CALL NDF_HNDLR( "CLOSE_NDF", NDG1_HNDLR, .FALSE., STATUS )

*  Indicate that the PROVENANCE extension should be propagated by
*  default when NDF_PROP or NDF_SCOPY is called.
      CALL NDF_TUNE( 1, 'PXTPROVENANCE', STATUS )

*  End the error reporting context.
      CALL ERR_END( STATUS )

*  If no error has occurred, update the provenance information in each
*  NDF writen during the provenance block if required. 
      IF ( STATUS .EQ. SAI__OK ) THEN

*  See if the environment variable AUTOPROV is defined. If so, get its
*  value.
         CALL PSX_GETENV( 'AUTOPROV', AUTOPV, STATUS )

*  If the environment variable was not defined, annul the error, and 
*  indicate that it is not defined.
         IF( STATUS .EQ. PSX__NOENV ) THEN
            CALL ERR_ANNUL( STATUS )
            AUTOPV = ' '
         END IF

*  We only propagate provenance if AUTOPROV is set to '1', or if AUTOPROV 
*  is unset and at least one input NDF had a provenance extension.
         IF( AUTOPV .EQ. '1' .OR. AUTOPV .EQ. ' ' ) THEN

*  Purge duplicate entries from the two groups. These can be caused if
*  the same NDF is opened several times.
            CALL GRP_PURGE( WRGRP, WRGRP2, STATUS )
            CALL GRP_PURGE( RDGRP, RDGRP2, STATUS )

*  Loop round each output NDF
            CALL GRP_GRPSZ( WRGRP2, NW, STATUS )
            DO IW = 1, NW
               CALL GRP_GET( WRGRP2, IW, 1, WRNDF, STATUS )

*  Check no error has occurred.
               IF( STATUS .EQ. SAI__OK ) THEN 

*  Get an NDF identifier for it.
                  CALL NDF_OPEN( DAT__ROOT, WRNDF, 'UPDATE', 'OLD', 
     :                           INDF1, PLACE, STATUS )            

*  If the output NDF could not be opened (e.g. if it was a temporary NDF
*  that has since been deleted), annul the error and pass on.
                  IF( STATUS .NE. SAI__OK ) THEN
                     CALL ERR_ANNUL( STATUS )
                     INDF1 =  NDF__NOID
                      
*  Otherwise, see if this output NDF has a PROVENANCE extenion
                  ELSE
                     CALL NDF_XSTAT( INDF1, 'PROVENANCE', THERE, 
     :                               STATUS )
                  END IF

*  Only modify this output NDF if is exists and has no provenance
*  extension.
                  IF( .NOT. THERE .AND. INDF1 .NE. NDF__NOID ) THEN

*  Otherwise, loop round each input NDF, maintaining a flag that
*  indicates if any input NDF had a PROVENANCE extension.
                     INPRV = .FALSE.
                     CALL GRP_GRPSZ( RDGRP2, NR, STATUS )
                     DO IR = 1, NR
                        CALL GRP_GET( RDGRP2, IR, 1, RDNDF, STATUS )

*  Existing NDFs that were opened for UPDATE will be in both groups. Check
*  to make sure we are not establishing an NDF as its own parent. Also
*  check no error has occurred.
                        IF( WRNDF .NE. RDNDF .AND. 
     :                      STATUS .EQ. SAI__OK ) THEN 

*  Get an NDF identifier for it. This will fail if the NDF has been
*  deleted (e.g. if it was a temporary NDF), so annul the error if an 
*  error is reported.
                           CALL NDF_OPEN( DAT__ROOT, RDNDF, 'READ', 
     :                                    'OLD', INDF2, PLACE, STATUS )
                           IF( STATUS .NE. SAI__OK ) THEN
                              CALL ERR_ANNUL( STATUS )

*  Otherwise, modify the provenance information in INDF1 to include 
*  INDF2 as a parent of INDF1. This also transfers all the ancestors 
*  of INDF2 to INDF1.
                           ELSE
                              CALL NDG_PTPRV( INDF1, INDF2, ' ', 
     :                                        .FALSE., STATUS )

*  Set the flag that indicates if any INPUT NDF had a provenance extension.
                              CALL NDF_XSTAT( INDF2, 'PROVENANCE', 
     :                                        THERE, STATUS )
                              IF( THERE ) INPRV = .TRUE.

*  Annul the NDF identifiers.
                              CALL NDF_ANNUL( INDF2, STATUS )               
                           END IF
                        END IF
                     END DO

*  If none of the input NDFs had a provenance extension, delete the
*  provenance extension from the output NDF unless AUTOPROV indicates that
*  default provenance information should be stored in the output NDF.
                     IF( .NOT. INPRV .AND. AUTOPV .EQ. ' ' ) THEN
                        CALL NDF_XDEL( INDF1, 'PROVENANCE', STATUS )
                     END IF

                  END IF
   
                  IF( INDF1 .NE. NDF__NOID ) CALL NDF_ANNUL( INDF1,
     :                                                       STATUS )
               END IF
            END DO

*  Delete the GRP groups.
            CALL GRP_DELET( RDGRP2, STATUS )
            CALL GRP_DELET( WRGRP2, STATUS )
         END IF

      END IF

      CALL GRP_DELET( RDGRP, STATUS )
      CALL GRP_DELET( WRGRP, STATUS )

      END
