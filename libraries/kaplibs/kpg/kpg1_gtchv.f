      SUBROUTINE KPG1_GTCHV( NOPT, OPTS, PARAM, NVAL, IDEF, VALS, 
     :                       STATUS )
*+
*  Name:
*     KPG1_GTCHV

*  Purpose:
*     Obtain a vector of choices from the environment.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_GTCHV( NOPT, OPTS, PARAM, NVAL, IDEF, VALS, STATUS )

*  Description:
*     This routine gets NVAL strings from the user, selected from those
*     supplied in OPTS. The indices of the supplied strings within OPTS
*     are returned. The user supplies the strings in the form of a GRP
*     group expression, using the default GRP control characters.
*
*     The user may supply an integer value instead of a string, in which
*     case the integer is understood to be the index of the required string
*     within OPTS. If the supplied list of strings contains the integer
*     itself, then the integer is understood to be a string, not an index.

*  Arguments:
*     NOPT = INTEGER (Given)
*        The number of available options supplied in OPTS.
*     OPTS( NOPT ) = CHARACTER * ( * ) (Given)
*        An array holding the options from which the user must choose.
*        Leading and trailing white space is ignored. Blank options are
*        not allowed.
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter to use. 
*     NVAL = INTEGER (Given)
*        The number of choices required. The user must supply exactly
*        this number of choices.
*     IDEF( NVAL ) = INTEGER (Given)
*        The indices within OPTS of the default strings to use if a null (!) 
*        value is supplied for the parameter. If the first value is zero,
*        a null parameter value results in a PAR__NULL status being returned. 
*     VALS( NVAL ) = INTEGER (Returned)
*        The indices within OPTS of the selected options.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  Case is insignificant when comparing supplied strings with
*     available options.
*     -  A dynamic default is set for the parameter before accessing it if 
*     IDEF supplied suitable defaults. The default consists of a
*     comma-separated list of the default options.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-MAR-1998 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'PAR_ERR'          ! PAR error constants

*  Arguments Given:
      INTEGER NOPT
      CHARACTER OPTS( NOPT )*(*)
      CHARACTER PARAM*(*)
      INTEGER NVAL
      INTEGER IDEF( NVAL )

*  Arguments Returned:
      INTEGER VALS( NVAL )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      LOGICAL CHR_SIMLR          ! Are strings equal apart from case?
      CHARACTER*2 CHR_NTH        ! 'st', 'nd', 'rd' or 'th'

*  Local Variables:
      CHARACTER DEFSTR*80        ! Dynamic default
      CHARACTER TEXT*(GRP__SZNAM)! User-supplied string
      INTEGER I                  ! Index of supplied string
      INTEGER IAT                ! No. of character in string
      INTEGER J                  ! Index of available option
      INTEGER IGRP               ! GRP id. for group of supplied strings
      INTEGER NGOT               ! No. of strings obtained from the user
      INTEGER F                  ! Index of first non-blank character
      INTEGER L                  ! Index of last non-blank character
      INTEGER LSTAT              ! CHR status value
      LOGICAL PROMPT             ! Should a new group of strings be obtained?
*.

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check the supplied values are OK.
      IF( NOPT .LE. 0 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'N', NOPT )
         CALL ERR_REP( 'KPG1_GTCHV_1', 'KPG1_GTCHV: No. of supplied '//
     :                 'options (^N) is fewer than 1 (programming '//
     :                 'error).', STATUS )

      ELSE IF( NVAL .LE. 0 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'N', NVAL )
         CALL ERR_REP( 'KPG1_GTCHV_2', 'KPG1_GTCHV: No. of required '//
     :                 'options (^N) is fewer than 1 (programming '//
     :                 'error).', STATUS )

      ELSE IF( IDEF( 1 ) .NE. 0 ) THEN

         DO I = 1, NVAL
            IF( IDEF( I ) .LT. 1 .OR. IDEF( I ) .GT. NOPT ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'ITH', I )
               CALL MSG_SETC( 'ITH', CHR_NTH( I ) )
               CALL MSG_SETI( 'D', IDEF( I ) )
               CALL MSG_SETI( 'N', NOPT )

               CALL ERR_REP( 'KPG1_GTCHV_3', 'KPG1_GTCHV: The ^ITH '//
     :                       'default value (^D) is fewer than 1 or '//
     :                       'greater than the number of available '//
     :                       'options (^N) (programming error).', 
     :                       STATUS )
               GO TO 999

            END IF
         END DO

      ELSE
         DO J = 1, NOPT
            IF( OPTS( J ) .EQ. ' ' ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'JTH', J )
               CALL MSG_SETC( 'JTH', CHR_NTH( J ) )
               CALL ERR_REP( 'KPG1_GTCHV_4', 'KPG1_GTCHV: The ^JTH '//
     :                       'available option is blank (programming '//
     :                       'error).', STATUS )
               GO TO 999
            END IF         
         END DO
      END IF

*  If defaults are available, set up a dynamic default value for the
*  parameter.
      IF( IDEF( 1 ) .GT. 0 ) THEN

*  Create a comma separated list of the default options.
         DEFSTR = ' '
         IAT = 0
         DO I = 1, NVAL
            CALL CHR_FANDL( OPTS( IDEF( I ) ), F, L )
            CALL CHR_APPND( OPTS( IDEF( I ) )( F : L ), DEFSTR, IAT )
            CALL CHR_APPND( ',', DEFSTR, IAT )
         END DO

*  Set the dynamic default, ignoring the trailing comma.
         CALL PAR_DEF0C( PARAM, DEFSTR( : IAT - 1 ), STATUS )

      END IF

*  Initialise the identifier for the group of strings obtained from the
*  user. A new group will be created by the first call to KPG1_GTGRP.
      IGRP = GRP__NOID

*  Loop until NVAL valid choices are obtained, or an error occurs.
      PROMPT = .TRUE.
      DO WHILE( PROMPT .AND. STATUS .EQ. SAI__OK ) 

*  Get a group of strings from the user. A new group is created if
*  necessary, or any existing group is emptied.
         CALL KPG1_GTGRP( PARAM, IGRP, NGOT, STATUS )

*  If a null parameter value was supplied, and if a default choice is
*  available, annull the error and return the default choice.
         IF( STATUS .EQ. PAR__NULL .AND. IDEF( 1 ) .GT. 0 ) THEN
            CALL ERR_ANNUL( STATUS )

            DO I = 1, NVAL            
               VALS( I ) = IDEF( I )
            END DO

            NGOT = NVAL
            PROMPT = .FALSE.

*  If no error has occurred, check each choice is OK.
         ELSE IF( STATUS .EQ. SAI__OK ) THEN

*  Assume for the moment that all the supplied string are OK, so that we
*  do not need to re-prompt.
            PROMPT = .FALSE.

*  Loop round each supplied string.
            DO I = 1, NGOT
               CALL GRP_GET( IGRP, I, 1, TEXT, STATUS )

*  First check to see if the string matches any of the supplied options.
*  Remove any leading white space in the supplied text.
               CALL CHR_LDBLK( TEXT )

*  Initialise the index of the matching option to zero. This indicates we
*  have no match as yet.
               VALS( I ) = 0

*  Loop round each available option.
               DO J = 1, NOPT

*  Find the indices of the first and last non-blank characters in this
*  option.
                  CALL CHR_FANDL( OPTS( J ), F, L )

*  See if this option matches the current user-supplied string (ignoring
*  case). Store its index if it does, and leave the loop.
                  IF( CHR_SIMLR( OPTS( J )( F : L ), TEXT ) ) THEN
                     VALS( I ) = J
                     GO TO 10
                  END IF

               END DO

 10            CONTINUE

*  If no match was found, see if the supplied string is an integer in the
*  range 1 to the number of supplied options. If so, save the index.
               IF( VALS( I ) .EQ. 0 ) THEN
                  LSTAT = SAI__OK
                  CALL CHR_CTOI( TEXT, J, LSTAT )
                  IF( LSTAT .EQ. SAI__OK ) THEN
                     IF( J .GT. 0 .AND. J .LE. NOPT ) THEN
                        VALS( I ) = J
                     END IF
                  END IF
               END IF

*  If we still have no match, report an error, flush it, indicate that we
*  need to re-prompt, and leave the loop.
               IF( VALS( I ) .EQ. 0 .AND. STATUS .EQ. SAI__OK ) THEN
                  STATUS = SAI__ERROR

                  CALL MSG_SETC( 'T', '''' )
                  CALL MSG_SETC( 'T', TEXT )
                  CALL MSG_SETC( 'T', '''' )
                  CALL MSG_SETC( 'PAR', PARAM )
                  CALL ERR_REP( 'KPG1_GTCHV_6', '^T is not a '//
     :                          'valid option for parameter %^PAR.',
     :                          STATUS )

                  CALL MSG_SETC( 'OPTS', '''' )
                  CALL CHR_FANDL( OPTS( 1 ), F, L )
                  CALL MSG_SETC( 'OPTS', OPTS( 1 )( F : L ) )
                  CALL MSG_SETC( 'OPTS', '''' )

                  DO J = 2, NOPT
                     CALL MSG_SETC( 'OPTS', ',' )
                     CALL MSG_SETC( 'OPTS', '''' )
                     CALL CHR_FANDL( OPTS( J ), F, L )
                     CALL MSG_SETC( 'OPTS', OPTS( J )( F : L ) )
                     CALL MSG_SETC( 'OPTS', '''' )
                  END DO

                  CALL ERR_REP( 'KPG1_GTCHV_7', 'Valid options are: '//
     :                          '^OPTS', STATUS )

                  CALL MSG_SETI( 'N', NOPT )
                  CALL ERR_REP( 'KPG1_GTCHV_8', 'Options may also be '//
     :                          'specified by index in the range 1 to'//
     :                          ' ^N.', STATUS )

                  CALL ERR_FLUSH( STATUS )
                  PROMPT = .TRUE.
                  GO TO 20

               END IF

*  Check the next supplied string.
            END DO

 20         CONTINUE

         END IF

*  If all the supplied values were OK, report an error if the number of 
*  values supplied is not correct.
         IF( .NOT. PROMPT .AND. NGOT .NE. NVAL .AND. 
     :       STATUS .EQ. SAI__OK ) THEN
            PROMPT = .TRUE.
            STATUS = SAI__ERROR

            IF( NGOT .EQ. 1 ) THEN
               CALL MSG_SETC( 'NGOT', '1 value has' )
            ELSE
               CALL MSG_SETI( 'NGOT', NGOT )
               CALL MSG_SETC( 'NGOT', ' values have' )
            END IF

            IF( NVAL .EQ. 1 ) THEN
               CALL MSG_SETC( 'NVAL', '1 value' )
            ELSE
               CALL MSG_SETI( 'NVAL', NVAL )
               CALL MSG_SETC( 'NVAL', ' values' )
            END IF

            CALL MSG_SETC( 'PAR', PARAM )
            CALL ERR_REP( 'KPG1_GTCHV_5', '^NGOT been supplied for '//
     :                    'parameter %^PAR. You must supply exactly '//
     :                    '^NVAL.', STATUS )

*  Flush the error so the user sees it immediately.
            CALL ERR_FLUSH( STATUS )

         END IF

*  If a new set of values is required, Tell the user, and cancel the
*  parameter value.
         IF( PROMPT .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR

            CALL MSG_SETC( 'PAR', PARAM )
            IF( NVAL .EQ. 1 ) THEN
               CALL ERR_REP( 'KPG1_GTCHV_9', 'Please supply a new '//
     :                       'value for parameter %^PAR.', STATUS )
            ELSE 
               CALL ERR_REP( 'KPG1_GTCHV_10', 'Please supply new '//
     :                       'values for parameter %^PAR.', STATUS )
            END IF

            CALL ERR_FLUSH( STATUS )
            CALL PAR_CANCL( PARAM, STATUS )

         ENDIF

      END DO

 999  CONTINUE

*  Delete the group.
      IF( IGRP .NE. GRP__NOID ) CALL GRP_DELET( IGRP, STATUS )

      END
