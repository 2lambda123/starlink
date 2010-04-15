      SUBROUTINE KPS1_FORED( M, N, IN, OUT, WORK, STATUS )
*+
*  Name:
*     KPS1_FOREx

*  Purpose:
*     Does a reverse FFT of a 2-d array held in Hermitian form.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_FOREx( M, N, IN, OUT, WORK, STATUS )

*  Description:
*     Does a reverse FFT of a single 2-d array which is assumed to be
*     an FFT held in Hermitian form, with the zero-frequency pixel at
*     the array centre.  The output is a single real array.

*  Arguments:
*     M = INTEGER (Given)
*        The number of columns per line in the input Fourier transform.
*     N = INTEGER (Given)
*        The number of lines in the input Fourier transform.
*     IN( M, N ) = ? (Given and Returned)
*        On input it is the Hermitian array.  On output it has its
*        quadrants swapped such that the zero frequency is at the
*        corners.
*     OUT( M, N ) = ? (Returned)
*        The real array.
*     WORK( * ) = ? (Returned)
*        Work space. Must be at least ( 3*max(m,n)+15 ) elements long.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for real and double-precision floating-
*     point data: replace "x" in the routine name by D or R as
*     appropriate.  The arrays supplied to the routine must have the
*     data type specified.

*  Copyright:
*     Copyright (C) 1988, 1990 Science & Engineering Research Council.
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: D.S. Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1988 Jun 6 (DSB):
*        Original version.
*     1990 Mar 13 (MJC):
*        Converted to KAPPA and reordered the arguments.
*     17-FEB-1995 (DSB):
*        Converted to use FFTPACK instead of NAG.  Re-format comments
*        in edstar style.  Size of work array changed.
*     1995 March 29 (MJC):
*        Used a modern style of variable declaration.  Used conditional
*        message reporting.  Removed unnecessary variables.
*     1995 March 30 (MJC):
*        Made generic from FFTREV.
*     1995 June 22 (MJC):
*        Added IN argument to avoid violation of the ANSI standard in
*        call to KPG1_FFTBx.
*     {enter_further_changes_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MSG_PAR'          ! Message-system constants

*  Arguments Given:
      INTEGER M
      INTEGER N

*  Arguments Given and Returned:
      DOUBLE PRECISION IN( M, N )

*  Arguments Returned:
      DOUBLE PRECISION OUT( M, N )
      DOUBLE PRECISION WORK( * )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER J                  ! X-axis (column) counter
      INTEGER K                  ! Y-axis (line) counter
      INTEGER MHP1               ! m / 2 + 1
      INTEGER MM1H               ! ( m-1 ) / 2
      INTEGER MP1H               ! ( m+1 ) / 2
      INTEGER NHP1               ! n / 2 + 1
      INTEGER NM1H               ! ( n-1 ) / 2
      INTEGER NP1H               ! ( n+1 ) / 2

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set up frequently used constants.
      MHP1 = 1 + M / 2
      MP1H = ( M + 1 ) / 2
      MM1H = ( M - 1 ) / 2
      NHP1 = 1 + N / 2
      NM1H = ( N - 1 ) / 2
      NP1H = ( N + 1 ) / 2

*  Give an informational message.
      CALL MSG_BLANKIF( MSG__NORM, STATUS )
      CALL MSG_OUTIF( MSG__NORM, 'INFOREV1',
     :                'Doing inverse transformation', STATUS )
      CALL MSG_BLANKIF( MSG__NORM, STATUS )

*  Swap the quadrants round so that zero frequencies are at the
*  corners.
      DO K = 1, N

         DO J = 1, MM1H
            WORK( J ) = IN( J, K )
         END DO

         DO J = MP1H, M
            IN( J - MM1H, K ) = IN( J, K )
         END DO

         DO J = 1, MM1H
            IN( J + MHP1, K ) = -WORK( J )
         END DO

      END DO


      DO J = 1, M

         DO K = 1, NM1H
            WORK( K ) = IN( J, K )
         END DO

         DO K = NP1H, N
            IN( J, K - NM1H ) = IN( J, K )
         END DO

         DO K = 1, NM1H
            IN( J, K + NHP1 ) = -WORK( K )
         END DO

      END DO

*  Fourier transform the image.
      CALL KPG1_FFTBD( M, N, IN, WORK, OUT, STATUS )

      END
