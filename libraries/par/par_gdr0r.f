      SUBROUTINE PAR_GDR0R( PARAM, DEFAUL, VMIN, VMAX, NULL, VALUE,
     :                        STATUS )
 
*+
*  Name:
*     PAR_GDR0x
 
*  Purpose:
*     Obtains a scalar value within a given range from a parameter.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL PAR_GDR0x( PARAM, DEFAUL, VMIN, VMAX, NULL, VALUE, STATUS )
 
*  Description:
*     This routine obtains from a parameter a scalar value that lies
*     within a supplied range of acceptable values.  A dynamic default
*     may be defined.
 
*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter.
*     DEFAUL = ? (Given)
*        The suggested-default value for the parameter.  No default
*        will be suggested when DEFAUL is not within the range of
*        acceptable values defined by VMIN and VMAX.
*     VMIN = ? (Given)
*        The value immediately above a range wherein the obtained
*        value cannot lie.  Thus if VMAX is greater than VMIN, VMIN
*        is the minimum allowed for the obtained value.  However,
*        should VMAX be less than VMIN, all values are acceptable
*        except those between VMAX and VMIN exclusive.
*     VMAX = ? (Given)
*        The value immediately below a range wherein the obtained
*        value cannot lie.  Thus if VMAX is greater than VMIN, VMAX
*        is the maximum allowed for the obtained value.  However,
*        should VMAX be less than VMIN, all values are acceptable
*        except those between VMAX and VMIN exclusive.
*     NULL = LOGICAL (Given)
*        NULL controls the behaviour of this routine when the parameter
*        is in the null state.  If NULL is .FALSE., this routine
*        returns with STATUS=PAR__NULL.  If NULL is .TRUE., the
*        returned VALUE takes the value of DEFAUL and, if the MSG filtering
*        level (see SUN/104) is 'verbose', a message informs the user of the
*        value used for the parameter. The routine then returns with 
*        STATUS=SAI__OK.  This feature is intended for
*        convenient handling of null values.  NULL should only be set
*        to .TRUE. when the value of DEFAUL will always give a
*        reasonable value for the parameter.
*     VALUE  = ? (Returned)
*        The value associated with the parameter.  If STATUS is returned
*        not equal to SAI__OK, VALUE takes the value of DEFAUL.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each of the data types double precision,
*     integer, and real: replace "x" in the routine name by D, I, or R
*     respectively as appropriate.  The DEFAUL, VMIN, VMAX, and VALUE
*     arguments all must have the corresponding data type.
*     -  If the value violates the constraint, the user is informed of
*     the constraint and prompted for another value.
 
*  Algorithm:
*     -  Find whether an inclusion or exclusion constraint is requested.
*     -  Suggest the default value to the parameter system, provided it
*     is within the range of acceptable values.
*     -  Set the maximum and minimum values.
*     -  Loop until an acceptable value is obtained or an error occurs.
*     Get a value from the parameter system.
*     -  If a bad status is returned from the parameter-system get, set
*     the returned value to the suggested default.  When the bad status
*     is PAR__NULL and the NULL flag is true, annul the error and
*     output a message.  The loop is exited.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     AJC: Alan J. Chipperfield   (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1991 January 1 (MJC):
*        Original based upon AIF_GTD0.
*     1991 February 1 (MJC):
*        Added the no-default option.
*     1992 November 18 (MJC):
*        Permitted the limits to be reversed in order to specify an
*        exclusion range.  Simplified the function and clarified the
*        description of parameter NULL.
*     1993 May 26 (MJC):
*        Used the PAR_MINx and PAR_MAXx routines rather than inline
*        code.
*     1999 September 16 (AJC):
*        Warn in MSG__VERB mode if NULL operates to adopt default.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE            ! Switch off default typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Environment constants
      INCLUDE 'PAR_ERR'        ! Parameter-system error constants
      INCLUDE 'MSG_PAR'        ! Message-system constants
 
*  Arguments Given:
      CHARACTER * ( * )
     :  PARAM                  ! Parameter name associated with value
                               ! to be obtained
 
      REAL
     :  DEFAUL,                ! Suggested default value for value to be
                               ! obtained
     :  VMIN,                  ! Minimum acceptable value for value to
                               ! be obtained
     :  VMAX                   ! Maximum acceptable value for value to
                               ! be obtained
 
      LOGICAL                  ! True if:
     :  NULL                   ! Default value used when bad status is
                               ! returned by the parameter get.
 
*  Arguments Returned:
      REAL
     :  VALUE                  ! Value only valid if STATUS does not
                               ! have an error value
 
*  Status:
      INTEGER STATUS           ! Global status
 
*  Local Variables:
      LOGICAL                  ! True if:
     :  EXCLUD,                ! The range is an exclusion zone
     :  NOTOK,                 ! No acceptable value obtained
     :  SUGDEF                 ! A default is to be suggested
 
*.
 
*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Find whether the range is inclusive or exclusive depending on the
*  polarity of the two values.
      EXCLUD = VMIN .GT. VMAX
 
*  Determine whether or not a suggested default is required.
      IF ( EXCLUD ) THEN
         SUGDEF = DEFAUL .LE. VMAX .OR. DEFAUL .GE. VMIN
      ELSE
         SUGDEF = DEFAUL .GE. VMIN .AND. DEFAUL .LE. VMAX
      END IF
 
*  Set the suggested value.
      IF ( SUGDEF ) CALL PAR_DEF0R( PARAM, DEFAUL, STATUS )
 
*  Set the range limits.
      CALL PAR_MINR( PARAM, VMIN, STATUS )
      CALL PAR_MAXR( PARAM, VMAX, STATUS )
 
*  Start a new error context.
      CALL ERR_MARK
 
*  Loop to obtain the value of the parameter.
*  ==========================================
 
*  Initialise NOTOK to start off the loop.
      NOTOK = .TRUE.
 
  100 CONTINUE
 
*  The loop will keep going as long as a suitable value has not be read
*  and there is no error.
         IF ( .NOT. NOTOK .OR. ( STATUS .NE. SAI__OK ) ) GOTO 120
 
*  Get a value for the parameter.
         CALL PAR_GET0R( PARAM, VALUE, STATUS )
 
*  A suitable value was obtained without error, so set the flag to exit
*  the loop.
         IF ( STATUS .EQ. SAI__OK ) THEN
            NOTOK = .FALSE.
 
*  Annul a null error to prevent an error report about null appearing.
*  Create a message informing the user of what has happened.
         ELSE
            IF ( STATUS .EQ. PAR__NULL .AND. NULL ) THEN
               CALL ERR_ANNUL( STATUS )
 
*  Inform the user what has happened.
               CALL MSG_SETR( 'DEFAULT', DEFAUL )
               CALL MSG_SETC( 'PARAM', PARAM )
               CALL MSG_OUTIF( MSG__VERB, 'PAR_GDR0R_DEFA',
     :           'A value of ^DEFAULT has been adopted '/
     :           /'for parameter ^PARAM.', STATUS )
            END IF
 
*  Set the returned value to the default.
            VALUE = DEFAUL
 
*  Terminate the loop.
            NOTOK = .FALSE.
         END IF
 
*  Go to the head of the loop.
         GOTO 100
 
*  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
*  Come here when the loop has been exited.
  120 CONTINUE
 
*  Release the new error context.
      CALL ERR_RLSE
 
      END
