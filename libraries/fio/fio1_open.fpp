#include <config.h>
      SUBROUTINE FIO1_OPEN( UNIT, FILE, FSTAT, FORMAT, ACCESS, RDONLY,
     :   CCNTL, CC, RECLEN, RECSZ, STATUS )
*+
*  Name:
*     FIO1_OPEN

*  Purpose:
*     Do the actual Fortran OPEN statement

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL FIO1_OPEN( UNIT, FILE, FSTAT, FORMAT, ACCESS, RDONLY,
*    :   CCNTL, CC, RECLEN, RECSZ, STATUS )

*  Description:
*     Execute the actual Fortran OPEN statement. This is isolated in a
*     subroutine as it contains machine dependent code.

*  Arguments:
*     UNIT = INTEGER (Given)
*        The FORTRAN unit number to be opened
*     FILE = CHARACTER * ( * ) (Given)
*        The name of the file to be opened.
*     FSTAT = CHARACTER * ( * ) (Given)
*        The open status of the file, i.e. the "STATUS=" option.
*     FORMAT = CHARACTER * ( * ) (Given)
*        The format of the file (FORMATTED or UNFORMATTED)
*     ACCESS = CHARACTER * ( * ) (Given)
*        The access mode (SEQUENTIAL, DIRECT or APPEND)
*     RDONLY = LOGICAL (Given)
*        Is the file to be opened read-only?
*     CCNTL = LOGICAL (Given)
*        Is the CARRIAGECONTROL option to be used?
*     CC = character * ( * ) (Given)
*        The value of the CARRIAGECONTROL option.
*     RECLEN = LOGICAL (Given)
*        Is the RECLEN option to be used?
*     RECSZ = INTEGER (Given)
*        The record length used when opening the file.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Features that can be used depending on the configuration:
*     -  READONLY option is tested and avoided if not supported
*     -  CARRIAGECONTROL option is tested and avoided if not supported
*     -  If ACCESS='APPEND' is attempted but not supported an error
*        will be triggered.
*     -  If RECL with SEQUENTIAL files is not supported, the RECLEN
*        LOGICAL is ignored and assumed to be false.

*  Copyright:
*     Copyright (C) 1992 Science & Engineering Research Council
*     Copyright (C) 2004 CLRC

*  Authors:
*     PMA: Peter Allan (Starlink, RAL)
*     TIMJ: Tim Jenness (JAC)
*     {enter_new_authors_here}

*  History:
*     11-FEB-1992 (PMA):
*        Original version.
*     12-MAR-1992 (PMA):
*        Change the call to FIO1_SERR to FIO_SERR.
*     3-APR-1992 (PMA):
*        Change the name of include files to lower case.
*     3-JUL-1992 (PMA):
*        Add a check on the value of the CC argument.
*     19-FEB-1993 (PMA):
*        Change the name of include files to upper case.
*     21-APR-2003 (TIMJ):
*        Now uses configure to disable/enable features
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'FIO_ERR'          ! FIO error constants

*  Arguments Given:
      CHARACTER * ( * ) ACCESS
      CHARACTER * ( * ) CC
      CHARACTER * ( * ) FILE
      CHARACTER * ( * ) FORMAT
      CHARACTER * ( * ) FSTAT
      INTEGER RECSZ
      INTEGER UNIT
      LOGICAL CCNTL
      LOGICAL RDONLY
      LOGICAL RECLEN

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER SYSERR             ! The Fortran I/O status value
      LOGICAL LREC               ! Internal copy of RECLEN

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

#if !HAVE_FC_OPEN_ACCESSAPPEND
*  ACCESS='APPEND' is attempted but not supported
      IF ( ACCESS .EQ. 'APPEND' ) THEN
         STATUS = FIO__IVFMT
         CALL EMS_REP( 'FIO1_OPEN_IVFMT',
     :        'Invalid FORMAT for opening file, ACCESS=APPEND not '//
     :        'supported', STATUS )
         GO TO 999
      END IF
#endif

#if HAVE_FC_OPEN_ACCESSSEQUENTIALRECL1
*  RECLEN with sequential files is supported so allow the option
      LREC = RECLEN
#else
*  RECLEN with sequential files is not supported so bypass code path
      LREC = .FALSE.      
#endif

*  Check that the carriage control option is valid.
      IF ( CC .NE. 'FORTRAN' .AND.
     :     CC .NE. 'LIST' .AND.
     :     CC .NE. 'NONE' ) THEN
         STATUS = FIO__IVFMT
         CALL EMS_REP( 'FIO1_OPEN_IVFMT',
     :      'Invalid FORMAT for opening file', STATUS )
      ELSE

*  Open the file.
         IF ( LREC ) THEN
            IF ( CCNTL ) THEN
               IF ( RDONLY ) THEN
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR,
#if HAVE_FC_OPEN_CARRIAGECONTROLCC
     :               CARRIAGECONTROL=CC, 
#endif
#if HAVE_FC_OPEN_READONLY
     :               READONLY, 
#endif
     :               RECL=RECSZ )
               ELSE
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR,
#if HAVE_FC_OPEN_CARRIAGECONTROLCC
     :               CARRIAGECONTROL=CC, 
#endif
     :               RECL=RECSZ)
               END IF
            ELSE
               IF ( RDONLY ) THEN
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR,
#if HAVE_FC_OPEN_READONLY
     :               READONLY,
#endif
     :               RECL=RECSZ)
               ELSE
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR,
     :               RECL=RECSZ )
               END IF
            END IF
         ELSE
            IF ( CCNTL ) THEN
               IF ( RDONLY ) THEN
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
#if HAVE_FC_OPEN_CARRIAGECONTROLCC
     :               CARRIAGECONTROL=CC, 
#endif
#if HAVE_FC_OPEN_READONLY
     :               READONLY,
#endif
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR)
               ELSE
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
#if HAVE_FC_OPEN_CARRIAGECONTROLCC
     :               CARRIAGECONTROL=CC, 
#endif
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR)
               END IF
            ELSE
               IF ( RDONLY ) THEN
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
#if HAVE_FC_OPEN_READONLY
     :               READONLY,
#endif
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR)
               ELSE
                  OPEN( UNIT=UNIT, FILE=FILE, STATUS=FSTAT, FORM=FORMAT,
     :               ACCESS=ACCESS, ERR=10, IOSTAT=SYSERR )
               END IF
            END IF
         END IF
      END IF
      GOTO 999

*  Handle any error condition.
   10 CALL FIO_SERR( SYSERR, STATUS )
      CALL FIO_PUNIT( UNIT, STATUS )

  999 CONTINUE
      END
