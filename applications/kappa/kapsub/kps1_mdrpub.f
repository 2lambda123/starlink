      SUBROUTINE KPS1_MDRPUB( STEP, IDIM1, IDIM2, ARRIN, ODIM1, ODIM2,
     :                         ARROUT, STATUS )
*+
*  Name:
*     KPS1_MDRPx

*  Purpose:
*     Expands the 2-dimensional array by replication of edge pixels.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_MDRPx( STEP, IDIM1, IDIM2, ARRIN, ODIM1, ODIM2, ARROUT,
*                      STATUS )

*  Description:
*     The input array, ARRIN, is copied into the central section of the
*     output array, ARROUT. The edges of ARROUT are then padded by
*     replication of the edge pixels of ARRIN. For example, with
*     STEP = 2 one corner of the input and output arrays would appear
*     as follows :
*
*                                              1 1 1 1 1 1 1
*                                              1 1 1 1 1 1 1
*     corner of     1 1 1 1 1   corresponding  1 1 1 1 1 1 1
*     input array : 1 2 2 2 2   corner of      1 1 1 2 2 2 2
*                   1 2 3 3 3   output array : 1 1 1 2 3 3 3
*                   1 2 3 4 4                  1 1 1 2 3 4 4
*                   1 2 3 4 5                  1 1 1 2 3 4 5
*
*     An immediate return will occur if STATUS has an error value on
*     entry.
*
*     Note: If ARROUT is not large enough to receive the array ARRIN,
*     together with its padding, only part of array ARRIN will be
*     copied.

*  Arguments:
*     STEP = INTEGER (Given)
*        The number of lines/columns of the output array which will be
*        padded by replication.
*     IDIM1 = INTEGER (Given)
*        The first dimension of the input 2-dimensional array.
*     IDIM2 = INTEGER (Given)
*        The second dimension of the input 2-dimensional array.
*     ARRIN( IDIM1, IDIM2 ) = ? (Given)
*        Data to be copied into the central section of the output
*        array.
*     ODIM1 = INTEGER (Given)
*        The first dimension of the output 2-dimensional array.
*     ODIM2 = INTEGER (Given)
*        The second dimension of the output 2-dimensional array.
*     ARROUT( ODIM1, ODIM2 ) = ? (Returned)
*        Will contain a copy of the input array in its central section
*        and will be padded at the edges by replicating the edge pixels
*        of the input array.
*     STATUS = INTEGER (Given)
*        This is the global status, if this variable has an error value
*        on entry then an immediate return will occur.

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     ARRIN and ARROUT arguments to the routine must have the data
*     type specified.

*  Algorithm:
*     If no error then
*        Copy input array into central area of output array
*        Replicate section of output array line corresponding to first
*          line of input array into corresponding section of first STEP
*          lines of output array
*        Replicate section of output array line corresponding to last
*          line of input array into corresponding section of last STEP
*          lines of output array
*        For all lines of output array
*           Replicate point in output array line corresponding to first
*             point of input array line into first STEP points of
*             output array line
*           Replicate point in output array line corresponding to last
*             point of input array line into last STEP points of output
*             array line
*        Endfor
*     Endif

*  Copyright:
*     Copyright (C) 1983-1984, 1986, 1989, 1993 Science & Engineering
*     Research Council. Copyright (C) 1995 Central Laboratory of the
*     Research Councils. All Rights Reserved.

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
*     DB: Dave Baines (ROE)
*     MJC: Malcolm J. Currie (STARLINK)
*     SMB: Steven Beard (ROE)
*     {enter_new_authors_here}

*  History:
*     24/10/1983 (DB):
*        Original version.
*     17/02/1984 (DB):
*        Documentation brought up to standard.
*     1986 September 9 (MJC):
*        Renamed parameters section to arguments and tidied.
*     1989 August 7 (MJC):
*        Passed array dimensions as separate variables.
*     1993 July 20 (SMB):
*        Modified to define the variables LASTX and LASTY in such a way
*        that the array ARROUT does not have to be exactly the right
*        size.  If it is too large it is only partly filled.  If it is
*        too small only part of the ARRIN array is copied.  This
*        modification was made to allow median filtering to be repeated
*        at different scale lengths while reusing the same work array.
*     1995 July 27 (MJC):
*        Made generic (from MEDREP).  Used a modern prologue and style.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SAE standard constants

*  Arguments Given:
      INTEGER STEP
      INTEGER IDIM1
      INTEGER IDIM2
      BYTE ARRIN( IDIM1, IDIM2 )
      INTEGER ODIM1
      INTEGER ODIM2

*  Arguments Returned:
      BYTE ARROUT( ODIM1, ODIM2 )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER FIRST              ! Position in output array of first
                                 ! line/column of input array
      INTEGER LASTX              ! Position in output array of last
                                 ! column of input array
      INTEGER LASTY              ! Position in output array of last line
                                 ! of input array
      INTEGER X                  ! X index to output array elements
      INTEGER XIN                ! X index to input array elements
      INTEGER Y                  ! Y index to output array elements
      INTEGER YIN                ! Y index to input array elements

*.


*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  FIRST is position in output array of line or column corresponding to
*  the first line or column of the input array.
      FIRST = STEP + 1

*  LASTX is position of column in output array corresponding to last
*  column of input array which may be accommodated.
      LASTX = MIN( STEP + IDIM2, ODIM1 - STEP )

*  LASTY, position in output array of line corresponding to last
*  line of THE input array which may be accommodated.
      LASTY = MIN( STEP + IDIM1, ODIM2 - STEP )

*  Copy the input array into the central section of the output array.
      DO Y = FIRST, LASTY
         YIN = Y - STEP

         DO  X = FIRST, LASTX
            XIN = X - STEP
            ARROUT( X, Y ) = ARRIN( XIN, YIN )
         END DO
      END DO

*  For first STEP lines of the output array.
      DO Y = 1, STEP

*  Replicate section of line corresponding to the first line of the
*  input array.
         DO X = FIRST, LASTX
            ARROUT( X, Y ) = ARROUT( X, FIRST )
         END DO
      END DO

*  For the last STEP lines of the output array.
      DO Y = LASTY+1, ODIM2

*  Replicate the section of the line corresponding to the last line of
*  the input array.
         DO X = FIRST, LASTX
            ARROUT( X, Y ) = ARROUT( X, LASTY )
         END DO
      END DO

*  For all lines of the output array.
      DO Y = 1, ODIM2

*  For the first STEP points in the line.
         DO X = 1, STEP

*  Replicate point corresponding to first in the input array line.
            ARROUT( X, Y ) = ARROUT( FIRST, Y )
         END DO

*  For the last STEP points in the line.
         DO X = LASTX + 1, ODIM1

*  Replicate point corresponding to the last in the input array line.
            ARROUT( X, Y ) = ARROUT( LASTX, Y )
         END DO
      END DO

      END
