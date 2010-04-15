      SUBROUTINE PAR_EXACI( PARAM, NVALS, VALUES, STATUS )
*+
*  Name:
*     PAR_EXACx

*  Purpose:
*     Obtains an exact number of values from a parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PAR_EXACx( PARAM, NVALS, VALUES, STATUS )

*  Description:
*     This routine obtains an exact number of values from a parameter
*     and stores them in a vector.  If the number of values obtained
*     is less than that requested, a further get or gets will occur
*     for the remaining values until the exact number required is
*     obtained (or an error occurs).  The routine reports how many
*     additional values are required prior to these further reads.
*     Should too many values be entered an error results and a further
*     read is attempted.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter.
*     NVALS = INTEGER (Given)
*        The number of values needed.  Values will be requested until
*        exactly this number of values (no more and no less) has been
*        obtained.
*     VALUES( NVALS ) = ? (Returned)
*        The values obtained from the parameter system.  They will only
*        be valid if STATUS is not set to an error value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  If the number of values is not positive then report the error
*     and exit.
*     -  Initialise the number of values obtained and needed.
*     -  Loop until no more values are needed or until an error occurs.
*     When more values are needed:
*        o  Obtain values associated with parameter.
*        o  Keep a tally of the number of values obtained and needed.
*        If too many or two few values were read report the number
*        required.  Cancel the parameter for a retry.
*        o  If an error occurred terminate the loop and exit with the
*        error status.
*     -  Supply the complete VALUES array back to the parameter system
*     provided status is good.

*  Notes:
*     -  There is a routine for each of the data types character,
*     double precision, integer, logical, and real: replace "x" in the
*     routine name by C, D, I, L, or R respectively as appropriate.  The
*     VALUES argument must have the corresponding data type.
*     -  If more than one attempt is made is to obtain the values, the
*     current value of the parameter will be only that read at the
*     last get, and not the full array of values.
*     - A PAR__ERROR status is returned when the number of values
*     requested is not positive.
*
*  Copyright:
*     Copyright (C) 1991, 1992, 1993 Science & Engineering Research Council.
*     Copyright (C) 1999 Central Laboratory of the Research Councils.
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
*     MJC: Malcolm J. Currie  (STARLINK)
*     AJC: Alan J. Chipperfield   (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 January 1 (MJC):
*        Original version based on Steven Beard's and the author's
*        AIF_EXAC.
*     1992 November 13 (MJC):
*        Restriction on the number of values was removed.  Re-tidied
*        the prologue
*     1993 June 2 (MJC):
*        Removed the usse of an HDS error constant.
*     1999 September 17 (AJC):
*        Replace MSG_OUT by MSG_OUTIF( MSG__QUIET
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! Switch off default typing

*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Environment constants
      INCLUDE 'PAR_ERR'        ! Parameter-system errors
      INCLUDE 'MSG_PAR'        ! MSG constants

*  Arguments Given:
      CHARACTER * ( * )
     :  PARAM                  ! Parameter name

      INTEGER
     :  NVALS                  ! Number of values to obtain

*  Arguments Returned:
      INTEGER
     :  VALUES( NVALS )        ! The values obtained from parameter
                               ! system

*  Status:
      INTEGER
     :  STATUS                 ! Global status

*  Local Variables:
      INTEGER
     :  NOBT,                  ! Number of values obtained in one
                               ! request
     :  NGOT,                  ! Number of values obtained so far
     :  NEEDED                 ! Number of values still needed

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Ensure that the number of values is positive.
      IF ( NVALS .GE. 1 ) THEN

*  Initialise the number of values obtained to zero and the number of
*  values needed to the number of values requested.
         NGOT   = 0
         NEEDED = NVALS

*  Start a new error context.
         CALL ERR_MARK

*  Loop until no more values are needed or until an error occurs.
  100    CONTINUE
            IF ( ( NEEDED .LE. 0 ) .OR. ( STATUS .NE. SAI__OK ) )
     :        GOTO 180

*  Check if any more values are needed.
  120       CONTINUE

*  Obtain the values associated with the parameter, filling the array
*  from the next element after those already obtained.  If too many
*  values are given, the parameter system will report the error, and
*  prompt for new values.
               CALL PAR_GETVI( PARAM, NEEDED, VALUES( NGOT + 1 ),
     :                           NOBT, STATUS )

*  Check the status returned.
               IF ( STATUS .EQ. SAI__OK ) THEN

*  Add the number of values obtained here to the number of values
*  obtained altogether, and subtract the number of values obtained from
*  the number of values needed.
                  NGOT = NGOT + NOBT
                  NEEDED = NEEDED - NOBT

*  If further values are still required then report this fact.
                  IF ( NEEDED .GT. 0 ) THEN

                     CALL MSG_SETI( 'NEEDED', NEEDED )
                     IF ( NEEDED .EQ. 1 ) THEN
                        CALL MSG_SETC( 'WORDS', 'value is' )
                     ELSE
                        CALL MSG_SETC( 'WORDS', 'values are' )
                     END IF
                     CALL MSG_OUTIF( MSG__QUIET, 'PAR_EXAC_NEEDED',
     :                 '^NEEDED more ^WORDS still needed.', STATUS )

*  Cancel the parameter for a retry.
                     CALL PAR_CANCL( PARAM, STATUS )

                  END IF

               ELSE

*  Some miscellaneous error has occurred.  Terminate the loop and exit
*  with the error status.
                  NEEDED = 0

               END IF

*  Go to the head of the loop if there are more values to be read.
               IF ( NEEDED .GT. 0 ) GOTO 120

*  Come here when the above loop exits.


*  Go to the head of the main loop.
            GOTO 100

*  Come here when the main loop exits.
  180    CONTINUE

*  Release the new error context.
         CALL ERR_RLSE

      ELSE

*  An error has occurred.
         STATUS = PAR__ERROR
         CALL MSG_SETC( 'PARAM', PARAM )

*  Non-physical number entered.  Report the error.
         CALL ERR_REP( 'PAR_EXACx_TOOFEW',
     :      'A non-positive number of values was requested for '/
     :      /'parameter ^PARAM. (Probable programming error.)', STATUS )

      END IF

      END
