      SUBROUTINE CON_INTCL( INTTYP, ITCODE, NBYTES, STATUS )
*+
*  Name:
*     CON_INTCL

*  Purpose:
*     Converts Interim data-type code from character to integer form and
*     obtains the number of bytes.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL CON_INTCL( INTTYP, ITCODE, NBYTES, STATUS )

*  Description:
*     Converts an Interim data-type code from character format to its
*     integer equivalent, e.g. from 102 to SW.  Also the number of
*     bytes per value for the data type is returned.

*  Arguments:
*     INTTYP = CHARACTER * 2 (Given)
*        The Interim data type: SB, SW, SL, DP, R, UB, UW.  If it is
*        not one of these, an error report is made and SAI__ERROR status
*        will be set.
*     ITCODE = INTEGER (Returned)
*        The Interim integer code for a data type.  0 is returned if the
*        type is not valid.
*     NBYTES = INTEGER (Returned)
*        The number of bytes used to store data in the given data type.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1992 February 4 (MJC):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * )
     :  INTTYP

*  Arguments Returned:
      INTEGER
     :  ITCODE,
     :  NBYTES

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER MAXTYP
      PARAMETER( MAXTYP=7 )

*  Local Variables:
      INTEGER
     :  BDFSIZ( MAXTYP ),        ! Byte lengths for the various Interim
                                 ! data types
     :  I,                       ! Loop counter
     :  TYPNUM( MAXTYP )         ! The table of Interim numeric data
                                 ! types

      CHARACTER * 2
     :  TYPES( MAXTYP )          ! The table of Interim numeric data
                                 ! types

*  Local Data:
      DATA TYPES/'SB', 'SW', 'SL',  'R', 'DP', 'UB', 'UW' /
      DATA TYPNUM/101, 102,  104,  204,  208,  301,  302/
      DATA BDFSIZ/1, 2, 4, 4, 8, 1, 2/

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop until a match is found.  Copy the type string to the output
*  argument. If none is found an error report will be made, otherwise
*  the routine exits.
      ITCODE = 0
      DO I = 1, MAXTYP
         IF ( INTTYP .EQ. TYPES( I ) ) THEN
            ITCODE = TYPNUM( I )
            NBYTES = BDFSIZ( I )
            GOTO 999
         END IF
      END DO

*  If an error occurred, then report a contextual message.
      STATUS = SAI__ERROR
      CALL MSG_SETC( 'TYPE', INTTYP )
      CALL ERR_REP( 'CON_INTCL_ERR',
     :  'Invalid Interim data type ^TYPE.  Unable to convert it to '/
     :  /'numeric form.', STATUS )

  999 CONTINUE
      END
