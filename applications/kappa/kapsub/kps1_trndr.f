      SUBROUTINE KPS1_TRNDR( FD, NELM, ARRAY, STATUS )
*+
*  Name:
*     KPS1_TRNDx

*  Purpose:
*     Reads a formatted ASCII file who records comprise data values
*     and stores in an array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_TRNDx( FD, NELM, ARRAY, STATUS )

*  Description:
*     This routine reads records from an ASCII file comprising data
*     values that are to be read into an array, usually for storage in
*     a standard form.  The records in the file may contain comments,
*     either whole lines or at the end of lines.  A comment is
*     recognised by the ! or # which starts it.  The values in the
*     record (less any comment) are converted to the required data type.

*  Arguments:
*     FD = INTEGER (Given)
*        Descriptor for the ASCII file containing records of numeric
*        values.
*     NELM = INTEGER (Given)
*        Dimension of the array to be filled with values from the file.
*     ARRAY( NELM ) = ? (Returned)
*        The array to be filled with values from the ASCII file.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for integer and floating-point data types:
*        replace "x" in the routine name by I, D, or R as appropriate.
*     -  A warning is reported if the shape does not use all the data
*     points in the file.

*  Prior Requirements:
*     - The file must have already been opened and should be rewound.

*  Copyright:
*     Copyright (C) 1990 Science & Engineering Research Council. All
*     Rights Reserved.

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
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1990 Jun 13 (MJC):
*        Original version.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER
     :  FD,
     :  NELM

*  Arguments Returned:
      REAL
     :  ARRAY( NELM )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER MAXLEN             ! Maximum length records that can be
                                 ! processed
      PARAMETER ( MAXLEN = 255 )
      INTEGER MXVALS             ! Maximum number of values per file
                                 ! record that can be processed
      PARAMETER ( MXVALS = ( MAXLEN + 1 ) / 2 )

*  Local Variables:
      INTEGER
     :  COM,                     ! Column where a comment starts in the
                                 ! input buffer
     :  HASH,                    ! Column where a hash is found in the
                                 ! input buffer
     :  I,                       ! Loop counter
     :  N,                       ! Number of data values read into the
                                 ! main array
     :  NC,                      ! Number of characters in a file
                                 ! record
     :  NREC,                    ! Number of records read from the file
     :  NVAL,                    ! Number of data values read from the
                                 ! file record
     :  SHRIEK                   ! Column where a shriek is found in the
                                 ! input buffer

      REAL
     :  LIST( MXVALS )           ! List of values read from the current
                                 ! record in the file

      CHARACTER * ( MAXLEN )
     :  BUFFER                   ! Buffer to hold a record from the file

*.

*    Check inherited global status.

      IF ( STATUS .NE. SAI__OK ) RETURN

*    Count the number of pixels read.

      N = 0

*    Assume that the file is rewound, though the only place where this
*    is used, the wording of the message does not make this assumption.

      NREC = 0

*    Loop for all records in the file, or until an error is encountered.

      DO WHILE ( N .LT. NELM .AND. STATUS .EQ. SAI__OK )

*       Read a line from the file into a buffer.

         CALL FIO_READ( FD, BUFFER, NC, STATUS )
         NREC = NREC + 1

*       Look for a comment.

         COM = 0
         SHRIEK = INDEX( BUFFER, '!' )
         HASH = INDEX( BUFFER, '#' )

*       We can skip the line if the first character is a comment
*       indicator.  If there is a trailing comment it should be removed
*       before extraction of the data occurs.  Find the leftmost comment
*       character.

         IF ( SHRIEK .GT. 1 .OR. HASH .GT. 1 ) THEN
            IF ( SHRIEK .GT. 1 .AND. HASH .GT. 1 ) THEN
               COM = MIN( SHRIEK, HASH )
            ELSE IF ( SHRIEK .GT. 1 ) THEN
               COM = SHRIEK
            ELSE IF ( HASH .GT. 1 ) THEN
               COM = HASH
            END IF

*       Place off to the right.  There may be no data, whill will get
*       trapped with comment lines.

         ELSE IF ( SHRIEK .EQ. 0 .AND. HASH .EQ. 0 ) THEN
            COM = NC + 1

*       A comment line.

         ELSE
            COM = 1
         END IF

*       There is no way of knowing if trailing values have been lost due
*       to a record longer than the maximum that can be stored.

         IF ( COM .GE. MAXLEN - 1 ) THEN
            CALL MSG_SETI( 'NREC', NREC )
            CALL MSG_OUT( 'RECTOOLONG', 'Record ^NREC from initial '/
     :        /'position may have been truncated.', STATUS )
         END IF

         IF ( COM .GT. 1 ) THEN

*          Trim the input buffer and extract the data values.

            CALL KPG1_PRSAR( BUFFER( 1:COM-1 ), MXVALS, LIST, NVAL,
     :                         STATUS )

*          If values were returned append to the data file.

            IF ( NVAL .GT. 0 ) THEN

*             Count the number of data values to prevent an access
*             violation.

               IF ( NVAL + N .GT. NELM ) THEN

*                Report a warning message.

                  CALL MSG_OUT( 'KPS1_TRNDR_TMANY',
     :              'The output array is full before all the input '/
     :              /'data values have been used.', STATUS )
                  NVAL = NELM - N
               END IF

*             Append the data just extracted from the string into the
*             main array.

               DO  I = 1, NVAL
                  N = N + 1
                  ARRAY( N ) = LIST( I )
               END DO
            END IF
         END IF
      END DO

      END
