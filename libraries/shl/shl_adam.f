      SUBROUTINE SHL_ADAM( LIBNAM, ISENV, STATUS )
*+
*  Name:
*     SHL_ADAM

*  Purpose:
*     Gives help about specified application

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     Subroutine

*  Invocation:
*     CALL SHL_ADAM( LIBNAM, STATUS )

*  Arguments:
*     LIBNAM = CHARACTER (Given)
*        Name of environment variable to use to obtain the location
*        of the required help library. _HELP is appended to the library
*        name, if not present, before translating environment variable.
*        Must translate to an actual help library file (the .shl
*        extension is optional).
*     ISENV = LOGIVAL (Given)
*        Indicates whether LIBNAM refers to an environment variable
*        that must be translated to obtain the actual name of the
*        help file (.TRUE.) or an actual help file with path. (.FALSE.)
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     Displays help from the specified help library and provides a method
*     to navigate the help system. Intended to be called from an ADAM
*     task subroutine directly with the name of the library to browse.
*     Expectation is that the ADAM parameters specified below will
*     be present in a correspondingly named IFL file. A template
*     IFL file is available.
*
*     See the Section "Navigating the Help Library" for details how to
*     move around the help information, and to select the topics you
*     want to view.

*  Usage:
*     xxxhelp [topic] [subtopic] [subsubtopic] [subsubsubtopic]

*  ADAM Parameters:
*     TOPIC = LITERAL (Read)
*        Topic for which help is to be given. [" "]
*     SUBTOPIC = LITERAL (Read)
*        Subtopic for which help is to be given. [" "]
*     SUBSUBTOPIC = LITERAL (Read)
*        Subsubtopic for which help is to be given. [" "]
*     SUBSUBSUBTOPIC = LITERAL (Read)
*        Subsubsubtopic for which help is to be given. [" "]

*  Algorithm:
*     -  Check for error on entry; return if not o.k.
*     -  Obtain topic and subtopics required.  Concatenate them
*        separated by spaces.
*     -  If an error has occurred set all topics to be null.
*     -  Get help on required topic.

*  Navigating the Help Library:
*     The help information is arranged hierarchically.  You can move
*     around the help information whenever XXXHELP prompts.  This
*     occurs when it has either presented a screen's worth of text or
*     has completed displaying the previously requested help.  The
*     information displayed by XXXHELP on a particular topic includes a
*     description of the topic and a list of subtopics that further
*     describe the topic.
*
*     At a prompt you may enter:
*        o  a topic and/or subtopic name(s) to display the help for that
*           topic or subtopic, so for example, "block parameters box"
*           gives help on BOX, which is a subtopic of Parameters, which
*           in turn is a subtopic of BLOCK;
*
*        o  a <CR> to see more text at a "Press RETURN to continue ..."
*           request;
*
*        o  a <CR>} at topic and subtopic prompts to move up one level
*           in the hierarchy, and if you are at the top level it will
*           terminate the help session;
*
*        o  a CTRL/D (pressing the CTRL and D keys simultaneously) in
*           response to any prompt will terminate the help session;
*
*        o  a question mark "?" to redisplay the text for the current
*           topic, including the list of topic or subtopic names; or
* 
*        o  an ellipsis "..." to display all the text below the
*           current point in the hierarchy.  For example, "BLOCK..."
*           displays information on the BLOCK topic as well as
*           information on all the subtopics under BLOCK.
*
*     You can abbreviate any topic or subtopic using the following
*     rules.
*
*        o  Just give the first few characters, e.g. "PARA" for
*           Parameters.
* 
*        o  Some topics are composed of several words separated by
*           underscores.  Each word of the keyword may be abbreviated,
*           e.g. "Colour_Set" can be shortened to "C_S".
* 
*        o  The characters "%" and "*" act as wildcards, where the
*           percent sign matches any single character, and asterisk
*           matches any sequence of characters.  Thus to display
*           information on all available topics, type an asterisk in
*           reply to a prompt.
*
*        o  If a word contains, but does end with an asterisk wildcard,
*           it must not be truncated.
* 
*        o  The entered string must not contain leading or embedded
*           spaces.
*
*     Ambiguous abbreviations result in all matches being displayed.

*  Implementation Status:
*     -  Uses the portable help system.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1986 November 14 (MJC):
*        Original.
*     1988 October 11 (MJC):
*        Fixed bug to enable subtopics to be accessed from the command
*        line.
*     1991 September 25 (MJC):
*        Corrected the description for the new layout in the new help
*        library, KAPPA.
*     1992 June 17 (MJC):
*        UNIX version using portable HELP.
*     1992 August 19 (MJC):
*        Rewrote the description, added usage and implementation status.
*     1995 November 9 (MJC):
*        Modified for UNIX and added the Topic on Navigation.
*     2004 July 25 (TIMJ):
*        Make standalone from KAPPA. Now in SHL. Additional argument.
*        Allow for optional .shl, optional _HELP and explicit filename.
*     {enter_further_changes_here}

*  Notes:
*     In order to use this routine from an A-task or monolith the
*     following steps are required:
*
*      1. Have an IFL file matching the correct parameters for the
*      name of the action as specified in the above section. testhelp.ifl
*      in the SHL distribution can be used as a template. (Copy it and
*      change the name)
*
*      2. The A-task/monolith subroutine can be very thin. The following
*      is perfectly adequate since this subroutine provides all the ADAM
*      code required for the help library:
*
*          SUBROUTINE MYHELP( STATUS )
*          CALL SHL_ADAM( 'MYHELP', .TRUE., STATUS )
*          END
*
*      which will read the environment variable call MYHELP_HELP.

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'        ! SSE global definitions

*  Arguments Give:
      CHARACTER * (*) LIBNAM   ! Name of help environment variable
      LOGICAL ISENV            ! Is LIBNAM a file or an env var?

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER
     :  CHR_LEN                ! Length of character strings ignoring
                               ! trailing blanks


*  Local Constants:
      INTEGER MAXLEV           ! Maximum number of help levels
      PARAMETER ( MAXLEV = 4 )

*  Local Variables:
      CHARACTER*19
     :  HLPTXT*80,             ! Composite command
     :  LIBRAY*132,            ! Library name and path
     :  PATH*122,              ! Library path
     :  TOPIC( MAXLEV ),       ! Name of the topic required
     :  ENVVAR*80              ! Environment variable to read

      INTEGER
     :  I,                     ! Loop counter
     :  NC                     ! Number of characters in the help string
                               ! less trailing blanks
      INTEGER IPOSN            ! Position in string
*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Read the environment variable if we have one
      IF ( ISENV ) THEN

*  Copy environment variable name into local storage
*  since we may need to modify it
         ENVVAR = LIBNAM

*  See if the envvar name include _HELP., appending if necessary
*  Start searching from the end of the string
         IPOSN = CHR_LEN( ENVVAR )
         CALL CHR_FIND( ENVVAR, '_HELP', .FALSE., IPOSN )
         IF (IPOSN .EQ. 0 ) THEN
*  Not found
            IPOSN = CHR_LEN( ENVVAR )
            CALL CHR_APPND( '_HELP', ENVVAR, IPOSN )
         END IF

*  Translate the environment variable/logical name.
         CALL PSX_GETENV( ENVVAR, PATH, STATUS )
      ELSE

*     Assume it is a help file directly
         PATH = LIBNAM

      END IF

      IF ( STATUS .EQ. SAI__OK ) THEN

*  Form the full library name. Appending .shl if not present already
         NC = CHR_LEN( PATH )
         LIBRAY = PATH( :NC )

*  Do we have .shl extension? Append one if not.
*  Start searching from the end of the string backwards
         IPOSN = NC
         CALL CHR_FIND( PATH, '.shl', .FALSE., IPOSN)
         IF (IPOSN .EQ. 0) THEN
*     Not found
            CALL CHR_APPND( '.shl', LIBRAY, NC )
         END IF


*  Get topic and subtopics.
         CALL PAR_GET0C( 'TOPIC', TOPIC(1), STATUS )
         CALL PAR_CANCL( 'TOPIC', STATUS )

         CALL PAR_GET0C( 'SUBTOPIC', TOPIC(2), STATUS )
         CALL PAR_CANCL( 'SUBTOPIC', STATUS )

         CALL PAR_GET0C( 'SUBSUBTOPIC', TOPIC(3), STATUS )
         CALL PAR_CANCL( 'SUBSUBTOPIC', STATUS )

         CALL PAR_GET0C( 'SUBSUBSUBTOPIC', TOPIC(4), STATUS )
         CALL PAR_CANCL( 'SUBSUBSUBTOPIC', STATUS )

*  Concatenate the help topics into a single string
         HLPTXT = TOPIC( 1 )
         NC = CHR_LEN( TOPIC( 1 ) ) + 1
         DO I = 2, MAXLEV
            CALL CHR_APPND( ' '//TOPIC( I ), HLPTXT, NC )
         END DO

*  Use a null string when something has gone wrong obtaining the
*  topics and sub-topics.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            HLPTXT = '         '
         END IF

*  Get help text.
         CALL SHL_GETHLP( LIBRAY, HLPTXT, STATUS )
      END IF

      END
