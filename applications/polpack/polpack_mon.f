      SUBROUTINE POLPACK_MON( STATUS )
*+
*  Name:
*     POLPACK_MON

*  Purpose:
*     Top-level POLPACK subroutine for A-task monolith on Unix.

*  Language:
*     UNIX Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL POLPACK_MON( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

* Description:

*     This is the top-level A-task monolith subroutine for the suite of A-tasks
*     associated with the POLPACK package. The chosen command is obtained from
*     the ADAM routine TASK_GET_NAME. The command may be specified from the
*     shell, ICL, StarTcl, etc. Given the command, the requested A-task is
*     called after a successful matching of the input string with a valid task
*     name.  If there is no match, an error report is made.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-JUN-1997 (DSB):
*        Original version, modified from equivalent IRCAMPACK routine.
*     10-NOV-1998 (DSB):
*        SEGMENT removed (POLKA now uses KAPPA:SEGMENT).
*     25-MAR-1999 (DSB):
*        Added POLSIM.
*     8-JUN-1999 (DSB):
*        Added POLSTACK.
*     20-SEP-2000 (DSB):
*        Set CAT tuning parameter QUIET to YES to suppress warnings about 
*        blank format strings.
*     23-NOV-2000 (DSB):
*        Added POLWRTCL.
*     7-DEC-2000 (DSB):
*        Added POLRDTCL.
*     {enter_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT  NONE              ! no implicit typing allowed

*  Global Constants:
      INCLUDE  'SAE_PAR'          ! SSE global definitions
      INCLUDE  'PAR_PAR'          ! Parameter system definitions

*  Status:
      INTEGER  STATUS

*  External References:
      INTEGER CHR_LEN             ! Length of a character string less
                                  ! any trailing blanks

*  Local Variables:
      CHARACTER NAME*( PAR__SZNAM ) ! Action name 

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Free up any compiled expressions currently in use by CAT. This should
*  be done by CAT itself, but it can't (at the moment).
      CALL ANT_XINIT( STATUS )

*  Stop CAT from complaining about blank format strings.
      CALL CAT_TUNES( 'QUIET', 'YES', STATUS )

*  Obtain the action name.
      CALL TASK_GET_NAME( NAME, STATUS )      

*  Define the current application name for history. The package version
*  number gets substituted in here when the POLPACK release source tar file 
*  is contructed.
      CALL NDF_HAPPN( NAME // ' (POLPACK 2.1-5)', STATUS )

*  Re-read the polpack configuration file.
      CALL POL1_CNFIG( STATUS )

*  Check the string against valid A-task names---if matched then call
*  the relevant A-task

      IF ( NAME .EQ. 'DATAPIC' ) THEN
         CALL DATAPIC( STATUS )

      ELSE IF ( NAME .EQ. 'POLBIN' ) THEN
         CALL POLBIN( STATUS )

      ELSE IF ( NAME .EQ. 'POLCAL' ) THEN
         CALL POLCAL( STATUS )

      ELSE IF ( NAME .EQ. 'POLEXP' ) THEN
         CALL POLEXP( STATUS )

      ELSE IF ( NAME .EQ. 'POLEXPX' ) THEN
         CALL POLEXPX( STATUS )

      ELSE IF ( NAME .EQ. 'POLEXT' ) THEN
         CALL POLEXT( STATUS )

      ELSE IF ( NAME .EQ. 'POLIMP' ) THEN
         CALL POLIMP( STATUS )

      ELSE IF ( NAME .EQ. 'POLIMPX' ) THEN
         CALL POLIMPX( STATUS )

      ELSE IF ( NAME .EQ. 'POLCENT' ) THEN
         CALL POLCENT( STATUS )

      ELSE IF ( NAME .EQ. 'POLHELP' ) THEN
         CALL POLHELP( STATUS )

      ELSE IF ( NAME .EQ. 'POLIMAGE' ) THEN
         CALL POLIMAGE( STATUS )

      ELSE IF ( NAME .EQ. 'POLKA' ) THEN
         CALL POLKA( STATUS )

      ELSE IF ( NAME .EQ. 'POLPLOT' ) THEN
         CALL POLPLOT( STATUS )

      ELSE IF ( NAME .EQ. 'POLPREP' ) THEN
         CALL POLPREP( STATUS )

      ELSE IF ( NAME .EQ. 'POLRDTCL' ) THEN
         CALL POLRDTCL( STATUS )

      ELSE IF ( NAME .EQ. 'POLSIM' ) THEN
         CALL POLSIM( STATUS )

      ELSE IF ( NAME .EQ. 'POLSTACK' ) THEN
         CALL POLSTACK( STATUS )

      ELSE IF ( NAME .EQ. 'POLVEC' ) THEN
         CALL POLVEC( STATUS )

      ELSE IF ( NAME .EQ. 'POLVERSION' ) THEN
         CALL POLVERSION( STATUS )

      ELSE IF ( NAME .EQ. 'POLWRTCL' ) THEN
         CALL POLWRTCL( STATUS )

      ELSE

*  No such option exists.

         STATUS = SAI__ERROR
         CALL MSG_SETC( 'CMD', NAME )
         CALL ERR_REP( 'POLPACK_MON_NOCOM',
     :     'POLPACK: No such command ^CMD.', STATUS )

      END IF

*  End and return.

      END
