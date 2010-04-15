      SUBROUTINE PARGET( STATUS )
*+
*  Name:
*     PARGET

*  Purpose:
*     Obtains the value or values of an application parameter.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL PARGET( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application reports the value or values of a parameter from
*     a named task.  It does this by searching the parameter file of
*     the task.  The purpose is to offer an easier-to-use interface for
*     passing values (especially output parameters) between tasks in
*     shell scripts.  The values are formatted in lines with as many
*     values as can be accommodated across the screen up to a maximum of
*     132 characters; values are space separated.  However, in scripts
*     the values are likely to be written to a script variable.  Thus
*     for example in the C-shell:
*
*        set med = `parget median histat`
*
*     would redirect the output to shell variable med, and thus a
*     reference to $med would substitute the median value obtained the
*     last time application HISTAT was invoked.  If the parameter
*     comprises a vector of values these can be stored in a C-shell
*     array.  For instance,
*
*        set perval = `parget perval histat`
*
*     would assign elements of the shell array perval[1], perval[2],
*     etc. to the last-computed percentile values of HISTAT.
*
*     Single elements of an parameter array may also be accessed using
*     the array index in parentheses.

*  Usage:
*     parget parname applic

*  ADAM Parameters:
*     APPLIC = LITERAL (Read)
*        The name of the application from which the parameter comes.
*     PARNAME = LITERAL (Read)
*        The parameter whose value or values are to be reported.

*  Examples:
*     parget mean stats
*        Report the value of parameter MEAN for the application STATS.
*     parget mincoord \
*        This reports the values of parameter MINCOORD of the current
*        application, in this case STATS.
*     parget applic=ndftrace parname=flabel(2)
*        This reports the value of the second element of parameter
*        FLABEL for the application NDFTRACE.

*  Notes:
*     -  The parameter file is located in the $ADAM_USER directory, if
*     defined, otherwise in the adam subdirectory of $HOME.  If it
*     cannot be located there, the task reports an error.
*     -  The parameter must exist in the selected application parameter
*     file and not be a structure, except one of type ADAM_PARNAME.
*     -  This task is not designed for use with ICL, where passing
*     parameter values is quite straightforward.  It does not operate
*     with monolith parameter files.

*  Copyright:
*     Copyright (C) 1995 Science & Engineering Research Council
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
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
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1995 August 15 (MJC):
*        Original version.
*     5-JUN-1998 (DSB):
*        Use DAT_SHAPE to determine if the parameter is a scalar instead
*        of DAT_SIZE.  DAT_SIZE does not distinguish between a scalar
*        and an array with only one element.
*     4-OCT-2004 (TIMJ):
*        Use ONE_SCRSZ rather than KPG1_SCRSZ.
*     2005 September 2 (MJC):
*        Use internal parameter OBJECT to obtain a pointer to the
*        full path, such that an array index can be appended to
*        access a single element of an array of parameter values.
*        Increase the maximum path length.
*     2-FEB-2006 (TIMJ):
*        Use HDS_FIND rather than attempting to kluge DAT_ASSOC
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'DAT_PAR'          ! DAT__ constants

*  Status:
      INTEGER STATUS             ! Global inherited status

*  External References:
      INTEGER CHR_LEN            ! Length of character strings ignoring
                                 ! trailing blanks

*  Local Constants:
      INTEGER BUFLEN             ! Maximum number of characters in a
                                 ! line of output
      PARAMETER ( BUFLEN = 132 )

      INTEGER MXCHAR             ! Maximum number of characters in line
                                 ! of output before new line is started
      PARAMETER ( MXCHAR = 80 )

*  Local Variables:
      CHARACTER * ( DAT__SZNAM ) APPLIC ! Name of application
      CHARACTER * ( BUFLEN ) BUFFER ! Buffer to hold output
      CHARACTER * ( BUFLEN ) CVALUE ! A value (stored as a string)
      INTEGER DIM( DAT__MXDIM )  ! Object dimensions
      INTEGER EL                 ! Number of elements returned
      CHARACTER * ( 256 ) FILE   ! Path to the filename
      INTEGER HEIGHT             ! Height of the screen in characters
      INTEGER I                  ! Loop counter
      CHARACTER * ( DAT__SZLOC ) LOC ! Locator to the parameter file
      CHARACTER * ( DAT__SZLOC ) LOCO ! Locator to the object
      CHARACTER * ( DAT__SZLOC ) LOCS ! Locator to the structure object
      CHARACTER * ( DAT__SZLOC ) LOCV ! Locator to the vectorised object
      INTEGER NC                 ! Number of characters in the buffer
      INTEGER NCV                ! Number of characters in the value
                                 ! string
      INTEGER NDIM               ! No. of dimensions
      CHARACTER * ( DAT__SZNAM ) PARNAM ! Name of parameter
      CHARACTER * ( 256 ) PATH   ! Path to the object
      LOGICAL PRIM               ! Object is primitive?
      INTEGER SIZE               ! Number of elements in object
      CHARACTER * ( DAT__SZLOC ) SLICE ! Locator to an element of the
                                 ! object
      CHARACTER * ( DAT__SZTYP ) TYPE ! Data type of the object
      INTEGER WIDTH              ! Width of the screen in characters

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Variable initialising
      LOC = DAT__NOLOC

*  Translate the environment variable/logical name for ADAM_USER.
      CALL PSX_GETENV( 'ADAM_USER', PATH, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN

*  ADAM_USER may not be defined so annul the error and try a different
*  route to the parameter file.
         CALL ERR_ANNUL( STATUS )

*  Obtain the home directory.
         CALL PSX_GETENV( 'HOME', PATH, STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL ERR_REP( 'HOMELESS', '$HOME not defined.', STATUS )
            GOTO 999
         END IF

*  Generate the path of the ADAM_USER.
         NC = CHR_LEN( PATH )
         CALL CHR_APPND( '/adam', PATH, NC )

      ELSE

*  Find the length of the path for ADAM_USER.
         NC = CHR_LEN( PATH )

      END IF

*  Get the application and parameter name.
      CALL PAR_GET0C( 'APPLIC', APPLIC, STATUS )
      CALL PAR_GET0C( 'PARNAME', PARNAM, STATUS )

*  Remove any leading blanks.
      CALL CHR_LDBLK( APPLIC )
      CALL CHR_LDBLK( PARNAM )

      IF ( STATUS .EQ. SAI__OK ) THEN

*  Generate the full pathname to the file.
         CALL CHR_APPND( '/'//APPLIC, PATH, NC )
         FILE = PATH
         CALL CHR_APPND( '.'//PARNAM, PATH, NC )

*  Use HDS_FIND to open the file and the corresponding object path
         CALL HDS_FIND(DAT__ROOT, PATH, 'READ', LOCO, STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL MSG_SETC( 'PAR', PARNAM )
            CALL MSG_SETC( 'PATH', FILE )
            CALL ERR_REP( 'PARGET_NOOBJ',
     :        'There is no parameter ^PAR in file ^PATH.', STATUS )
            GOTO 999
         END IF

*  Find out if the object is primitive.
         PRIM = .FALSE.
         CALL DAT_PRIM( LOCO, PRIM, STATUS )

         IF ( .NOT. PRIM ) THEN

*  This may be acceptable if it is an ASSOCked parameter.  These are
*  structures of type ADAM_PARNAM.
            CALL DAT_ANNUL( LOCO, STATUS )
            CALL HDS_OPEN( FILE, 'READ', LOC, STATUS )
            CALL DAT_FIND( LOC, PARNAM, LOCS, STATUS )
            CALL DAT_TYPE( LOCS, TYPE, STATUS )

            IF ( TYPE .NE. 'ADAM_PARNAME' ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETC( 'PAR', PARNAM )
               CALL MSG_SETC( 'PATH', PATH )
               CALL ERR_REP( 'PARGET_NOOBJ',
     :           'Object ^PAR in file ^PATH is an arbitrary structure.',
     :           STATUS )
               GOTO 999

*  Obtain a locator to the desired value.
            ELSE
               CALL DAT_FIND( LOCS, 'NAMEPTR', LOCO, STATUS )
            END IF

*  Tidy the locator.
            CALL DAT_ANNUL( LOCS, STATUS )

         END IF

*  Find the number of elements associated with the object.
         CALL DAT_SHAPE( LOCO, DAT__MXDIM, DIM, NDIM, STATUS )
         IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Obtain and report a scalar value.
         IF ( NDIM .EQ. 0 ) THEN
            CALL DAT_GET0C( LOCO, CVALUE, STATUS )
            CALL MSG_OUT( 'VALUE', CVALUE, STATUS )

         ELSE

*  Find the height and width of the screen.  Use the full screen area.
*  Use a default when there has been an error.  Hide the error in its
*  own context.  Constrain the width to the size of the buffer.
            CALL ERR_MARK
            CALL ONE_SCRSZ( WIDTH, HEIGHT, STATUS )
            IF ( STATUS .NE. SAI__OK ) THEN
               CALL ERR_ANNUL( STATUS )
               WIDTH = MXCHAR
            ELSE
               WIDTH = MIN( BUFLEN, WIDTH )
            END IF
            CALL ERR_RLSE

*  Vectorise the object.
            CALL DAT_VEC( LOCO, LOCV, STATUS )

*  Initialise output string and length.
            BUFFER = ' '
            NC = 0

*  Loop for each object.
            CALL DAT_SIZE( LOCV, SIZE, STATUS )
            DO I = 1, SIZE

*  The following is not efficient, but saves coding time.
*  Obtain a single element.
               CALL DAT_SLICE( LOCV, 1, I, I, SLICE, STATUS )

*  Obtain the value.
               CALL DAT_GET1C( SLICE, 1, CVALUE, EL, STATUS )

*  Obtain the length of the value.
               NCV = CHR_LEN( CVALUE )

*  See if it can be appended to the current record, leaving a space
*  between values to delimit them.
               IF ( NCV + NC .LT. MXCHAR ) THEN
                  NC = NC + 1
                  CALL CHR_APPND( CVALUE, BUFFER, NC )
               ELSE

*  Report the values so far on this line.
                  CALL MSG_OUT( 'VALUE', BUFFER( :NC ), STATUS )

*  Start a new string.  Set the length of the buffer filled so far.
                  BUFFER = CVALUE
                  NC = NCV

               END IF

*  Annul the slice.
               CALL DAT_ANNUL( SLICE, STATUS )
            END DO

*  Report the remaining values.
            CALL MSG_OUT( 'VALUE', BUFFER( :NC ), STATUS )


*  Tidy the vectorised locator.
            CALL DAT_ANNUL( LOCV, STATUS )
         END IF

*  Tidy the HDS locator and close the file (if opened)
         CALL DAT_ANNUL( LOCO, STATUS )
         IF ( LOC .NE. DAT__NOLOC) CALL DAT_ANNUL( LOC, STATUS )

      END IF

  999 CONTINUE
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'PARGET_ERR',
     :     'PARGET: Unable to obtain a parameter value.', STATUS )
      END IF

      END
