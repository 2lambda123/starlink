      SUBROUTINE MSG_OUTIF( PRIOR, PARAM, TEXT, STATUS )
*+
*  Name:
*     MSG_OUTIF

*  Purpose:
*     Conditionally deliver the text of a message to the user.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL MSG_OUTIF( PRIOR, PARAM, TEXT, STATUS )

*  Description:
*     Depending upon the given value of the given message priority and 
*     the message filtering level set using MSG_IFSET, the message
*     text is either expanded and output to the user or discarded.
*     The values of any existing message tokens are always annulled by 
*     a call to MSG_OUTIF. If an output error occurs, an error is 
*     reported and the status argument returned set to MSG__OPTER.

*  Arguments:
*     PRIOR = INTEGER (Given)
*        Message output filter. This may be one of three values:
*        
*           -  MSG__QUIET = always output the message, regardless of the
*           output filter setting;
*           -  MSG__NORM = output the message if the current output
*           filter is set to either MSG__NORM or MSG__VERB;
*           -  MSG__VERB = output the message only if the current
*           output filter is set to MSG__VERB.
*
*        Here, the collating sequence:
*
*           MSG__QUIET < MSG__NORM < MSG__VERB
*           
*        may be assumed. Any other value will result in an error report
*        and the status being returned set to MSG__INVIF: no further 
*        action will be taken.
*     PARAM = CHARACTER * ( * ) (Given)
*        The message name.
*     TEXT = CHARACTER * ( * ) (Given)
*        The message text.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PCTR: P.C.T. Rees (STARLINK)
*     AJC: A. J. Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     10-JUN-1991 (PCTR):
*        Original version.
*     26-AUG-1992 (PCTR):
*        Call MSG1_FORM and MSG1_PRINT directly, instead of MSG_OUT
*        (MSG_OUT no calls MSG_OUTIF with PRIOR set to MSG__NORM).
*     25-JAN-1996 (AJC):
*        re-format CHARACTER declarations
*     15-SEP-1999 (AJC):
*        Add CLEAN argument to call MSG1_FORM
*     22-FEB-2001 (AJC):
*        Use MSG1_KTOK not EMS1_KTOK
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MSG_PAR'          ! MSG_ public constants
      INCLUDE 'MSG_ERR'          ! MSG_ error codes

*  Global Variables:
      INCLUDE 'MSG_CMN'          ! MSG_ output filter level

*  Arguments Given:
      INTEGER PRIOR

      CHARACTER * ( * ) PARAM
      CHARACTER * ( * ) TEXT

*  Status:
      INTEGER STATUS

*  External Variables:
      EXTERNAL MSG1_BLK          ! Force inclusion of block data

*  Local Variables:
      INTEGER MSGLEN             ! Message length

      CHARACTER * ( MSG__SZMSG ) MSGSTR ! Message string

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) THEN

*     Call MSG1_KTOK to annul any defined message tokens.
         CALL MSG1_KTOK
      ELSE

*     The given status is OK, so check that the given value of the
*     output filter is allowed.
         IF ( PRIOR .LT. MSG__QUIET .OR. PRIOR .GT. MSG__VERB ) THEN

*        The given message filtering level is out of range: set the
*        returned status and report an error. (Mark and subsequently 
*        release an error context to prevent token name clashes.)
            CALL EMS_MARK
            STATUS = MSG__INVIF
            CALL EMS_SETI( 'PRIOR', PRIOR )
            CALL EMS_REP( 'MSG_OUTIF_INVIF',
     :      'MSG_OUTIF: Invalid message filtering value:  ^PRIOR', 
     :      STATUS )
            CALL EMS_RLSE

*        Annul the message token table.
            CALL MSG1_KTOK
         ELSE

*        Conditionally output the given message.
            IF ( PRIOR .LE. MSGINF ) THEN

*           Form the output message string.
               CALL MSG1_FORM(
     :            PARAM, TEXT, .NOT.MSGSTM, MSGSTR, MSGLEN, STATUS )

*           Deliver the message string.
               CALL MSG1_PRINT( MSGSTR( : MSGLEN ), STATUS )
            ELSE

*           Call MSG1_KTOK to annul any defined message tokens, even
*           though the message was not output.
               CALL MSG1_KTOK
            END IF
         END IF
      END IF

      END
