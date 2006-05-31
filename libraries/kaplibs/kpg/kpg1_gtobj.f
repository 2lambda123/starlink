      SUBROUTINE KPG1_GTOBJ( PARAM, CLASS, ISA, IAST, STATUS )
*+
*  Name:
*     KPG1_GTOBJ

*  Purpose:
*     Get an AST Object from an NDF, FITS file or text file using an 
*     environment parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_GTOBJ( PARAM, CLASS, ISA, IAST, STATUS )

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The parameter name.
*     CLASS = CHARACTER * ( * ) (Given)
*        The required class. Used in error reports (see ISA). If Objects
*        of more than 1 class can be used, this should be supplied blank, and 
*        the calling routine should verify that the Object is usable.
*     ISA = EXTERNAL (Given)
*        A suitable AST "ISA.." function which returns .TRUE. if an Object
*        is of a suitable class. This is ignored if CLASS is blank.
*        Otherwise, an error is reported if th supplied Object is not of the
*        required class.
*     IAST = INTEGER (Returned)
*        The AST Object, or AST__NULL.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2001 Central Laboratory of the Research Councils.
*     Copyright (C) 2005 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-JAN-2001 (DSB):
*        Original version.
*     6-JAN-2005 (DSB):
*        Allow CLASS and ISA to specify particular subclasses of Frame.
*     31-MAY-2006 (DSB):
*        Move from ATL to KAPLIBS because of the NDF dependency.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants
      INCLUDE 'NDF_PAR'          ! NDF constants

*  Arguments Given:
      CHARACTER PARAM*(*)
      CHARACTER CLASS*(*)
      LOGICAL ISA

*  Arguments Returned:
      INTEGER IAST

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL ISA
      LOGICAL CHR_SIMLR

*  Local Variables:
      INTEGER IAST2
      INTEGER IGRP
      INTEGER INDF
      LOGICAL OK
*.

*  Initialise.
      IAST = AST__NULL

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Attempt to access the parameter as an NDF.
      CALL NDF_EXIST( PARAM, 'READ', INDF, STATUS )

*  If succesful, get the WCS FrameSet from it.
      IF( INDF .NE. NDF__NOID ) THEN
         CALL KPG1_GTWCS( INDF, IAST, STATUS )

*  Tell the user where the object came from. 
         IF( IAST .NE. AST__NULL ) THEN
            CALL NDF_MSG( 'NDF', INDF ) 
            CALL ATL_NOTIF( '   AST data read from NDF ''^NDF''.', 
     :                       STATUS )
         END IF

*  Annul the NDF identifer.
         CALL NDF_ANNUL( INDF, STATUS )

*  If it was not an NDF...
      ELSE

*  Obtain a GRP group containing text from which an Object is to be read.
         CALL ATL_GTGRP( PARAM, IGRP, STATUS )

*  Tried to read an object from the group.
         CALL ATL_RDGRP( IGRP, IAST, STATUS )

*  Delete the group.
         CALL GRP_DELET( IGRP, STATUS )

      END IF

*  Check the Object class if CLASS is not blank.
      IF( CLASS .NE. ' ' .AND. STATUS .EQ. SAI__OK ) THEN 

*  See if the object is of the required class.
         OK = ISA( IAST, STATUS ) 

*  If not, and if the object is a FrameSet, see if the current Frame is
*  of the required class. If so return a pointer to the current Frame.
         IF( AST_ISAFRAMESET( IAST, STATUS ) ) THEN
            IF( .NOT. OK ) THEN
               IAST2 = AST_GETFRAME( IAST, AST__CURRENT, STATUS )
               IF( ISA( IAST2, STATUS ) ) THEN
                  OK = .TRUE.
                  CALL AST_ANNUL( IAST, STATUS )
                  IAST = IAST2
               ELSE
                  CALL AST_ANNUL( IAST2, STATUS )
               END IF
            END IF

*  If not, see if the base to current Mapping is of the required class. If 
*  so return a pointer to the base to current Mapping.
            IF( .NOT. OK ) THEN
               IAST2 = AST_GETMAPPING( IAST, AST__BASE, AST__CURRENT, 
     :                                STATUS )
               IF( ISA( IAST2, STATUS ) ) THEN
                  OK = .TRUE.
                  CALL AST_ANNUL( IAST, STATUS )
                  IAST = IAST2
               ELSE
                  CALL AST_ANNUL( IAST2, STATUS )
               END IF
            END IF

         END IF

*  Report an error if we could not find an object of the correct class.
         IF( .NOT. OK .AND. STATUS .EQ. SAI__OK ) THEN
            IF( AST_ISAFRAMESET( IAST, STATUS ) ) THEN
               IAST2 = AST_GETFRAME( IAST, AST__CURRENT, STATUS )
               CALL MSG_SETC( 'C', AST_GETC( IAST2, 'CLASS', STATUS ) )
               CALL MSG_SETC( 'P', PARAM )
               CALL MSG_SETC( 'L', CLASS )
               STATUS = SAI__ERROR
               CALL ERR_REP( 'KPG1_GTOBJ_ERR1', '$^P contains a '//
     :                       'FrameSet representing a ^C, but a '//
     :                       '^L is required.', STATUS )
               CALL AST_ANNUL( IAST2, STATUS )
            ELSE
               CALL MSG_SETC( 'C', AST_GETC( IAST, 'CLASS', STATUS ) )
               CALL MSG_SETC( 'P', PARAM )
               CALL MSG_SETC( 'L', CLASS )
               STATUS = SAI__ERROR
               CALL ERR_REP( 'KPG1_GTOBJ_ERR2', '$^P contains a ^C, '//
     :                       'but a ^L is required.', STATUS )
            END IF
         END IF

      END IF

*  Annul the object if an error occurred.
      IF( STATUS .NE. SAI__OK ) CALL AST_ANNUL( IAST, STATUS )

      END
